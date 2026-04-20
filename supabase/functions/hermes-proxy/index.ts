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
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {

    // 1. Authenticate user with Firebase/Supabase Auth
    const authHeader = req.headers.get('Authorization')

    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
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
        headers: { 'Content-Type': 'application/json' },
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
          headers: { 'Content-Type': 'application/json' },
        })
      }

      // Check if subscription is active
      if (subscription.status !== 'active') {
        return new Response(JSON.stringify({
          error: 'Subscription inactive',
          message: 'Your subscription has expired. Please renew to continue.'
        }), {
          status: 403,
          headers: { 'Content-Type': 'application/json' },
        })
      }

      // Check expiration date
      if (subscription.expires_at && new Date(subscription.expires_at) < new Date()) {
        return new Response(JSON.stringify({
          error: 'Subscription expired',
          message: 'Your subscription has expired. Please renew to continue.'
        }), {
          status: 403,
          headers: { 'Content-Type': 'application/json' },
        })
      }
    }

    // 3. Parse the request
    const body: ChatRequest = await req.json()
    
    // Set default model if not provided
    if (!body.model) {
      body.model = 'gemini-3-flash-preview'
    }

    // 4. Forward request to Hermes Agent
    const hermesResponse = await fetch(`${HERMES_BASE_URL}/v1/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${HERMES_API_PASSWORD}`,
      },
      body: JSON.stringify(body),
    })

    // 5. Log usage (optional - for analytics/billing)
    // Use service role for database writes
    const supabaseServiceRole = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    await supabaseServiceRole.from('agent_usage').insert({
      user_id: user.id,
      model: body.model,
      message_count: body.messages.length,
      timestamp: new Date().toISOString(),
    })

    // 6. Return response to client
    const responseData = await hermesResponse.json()
    
    return new Response(JSON.stringify(responseData), {
      status: hermesResponse.status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    })

  } catch (error) {
    console.error('Error in hermes-proxy:', error)
    return new Response(JSON.stringify({ 
      error: 'Internal server error',
      message: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

