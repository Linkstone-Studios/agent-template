// Supabase Edge Function to proxy requests to Hermes Agent
// with authentication and subscription validation

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const HERMES_BASE_URL = Deno.env.get('HERMES_BASE_URL') || 'http://YOUR_DROPLET_IP:8642'
const HERMES_API_PASSWORD = Deno.env.get('HERMES_API_PASSWORD') || ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const SKIP_SUBSCRIPTION_CHECK = Deno.env.get('SKIP_SUBSCRIPTION_CHECK') === 'true'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ChatRequest {
  model?: string
  messages: Array<{
    role: string
    content: string
  }>
  stream?: boolean
}

serve(async (req) => {
  // CORS headers
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        ...corsHeaders,
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      },
    })
  }

  try {

    // 1. Authenticate user with Firebase/Supabase Auth
    const authHeader = req.headers.get('Authorization')

    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Create a Supabase client using the anon key for JWT validation
    // The anon key supports ES256 algorithm used by Supabase Auth
    const token = authHeader.replace('Bearer ', '')
    console.log('Token (first 50):', token.substring(0, 50))

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

    const { data: { user }, error: authError } = await supabase.auth.getUser(token)

    if (authError || !user) {
      return new Response(JSON.stringify({
        error: 'Invalid authentication token',
        details: authError?.message,
        tokenStart: token.substring(0, 30)
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log('User authenticated:', user.id)

    // 2. Check user's subscription status (optional for testing)
    // Create a service role client for database access (RLS bypassed)
    if (!SKIP_SUBSCRIPTION_CHECK) {
      const supabaseServiceRole = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
      const { data: subscription, error: subError } = await supabaseServiceRole
        .from('subscriptions')
        .select('status, plan_id, expires_at')
        .eq('user_id', user.id)
        .single()

      if (subError || !subscription) {
        return new Response(JSON.stringify({
          error: 'No active subscription found',
          message: 'Please subscribe to use the AI agent'
        }), {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Check if subscription is active
      if (subscription.status !== 'active') {
        return new Response(JSON.stringify({
          error: 'Subscription inactive',
          message: 'Your subscription has expired. Please renew to continue.'
        }), {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Check expiration date
      if (subscription.expires_at && new Date(subscription.expires_at) < new Date()) {
        return new Response(JSON.stringify({
          error: 'Subscription expired',
          message: 'Your subscription has expired. Please renew to continue.'
        }), {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // 3. Parse the request
    const body: ChatRequest = await req.json()
    
    // Set default model if not provided
    if (!body.model) {
      body.model = 'gemini-3-flash-preview'
    }

    // 4. Forward request to Hermes Agent with user context
    const startTime = Date.now()
    const hermesResponse = await fetch(`${HERMES_BASE_URL}/v1/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${HERMES_API_PASSWORD}`,
        // Pass user context to Hermes for tool authentication
        'X-User-ID': user.id,
        'X-User-Email': user.email || '',
        'X-Supabase-Token': token,  // Pass through original JWT for Supabase operations
      },
      body: JSON.stringify(body),
    })

    if (!hermesResponse.ok) {
      const errorText = await hermesResponse.text()
      console.error('Hermes error:', errorText)
      return new Response(JSON.stringify({
        error: 'Hermes API error',
        details: errorText
      }), {
        status: hermesResponse.status,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      })
    }

    // 5. Handle streaming vs non-streaming responses
    const supabaseServiceRole = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    if (body.stream) {
      // Streaming response - pipe through and log basic usage
      console.log('Streaming response from Hermes')

      // Log basic usage (can't get exact tokens from stream without parsing)
      const latency = Date.now() - startTime
      await supabaseServiceRole.from('ai_usage_logs').insert({
        user_id: user.id,
        provider: 'hermes',
        model: body.model,
        latency_ms: latency,
      })

      // Return streaming response with proper headers
      return new Response(hermesResponse.body, {
        status: hermesResponse.status,
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      })
    } else {
      // Non-streaming response - parse and log detailed usage
      const responseData = await hermesResponse.json()
      const latency = Date.now() - startTime

      // Extract token usage if available
      const usage = responseData.usage || {}
      const inputTokens = usage.prompt_tokens || null
      const outputTokens = usage.completion_tokens || null

      // Log detailed usage
      await supabaseServiceRole.from('ai_usage_logs').insert({
        user_id: user.id,
        provider: 'hermes',
        model: body.model,
        input_tokens: inputTokens,
        output_tokens: outputTokens,
        latency_ms: latency,
      })

      return new Response(JSON.stringify(responseData), {
        status: hermesResponse.status,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      })
    }

  } catch (error) {
    console.error('Error in hermes-proxy:', error)
    return new Response(JSON.stringify({
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

