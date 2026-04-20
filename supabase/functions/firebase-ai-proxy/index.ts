/**
 * Firebase AI Proxy Edge Function
 * 
 * This function acts as a secure proxy between the Flutter app and Google AI Studio API.
 * It prevents Denial-of-Wallet attacks by enforcing per-user rate limits and hiding API keys.
 * 
 * Security features:
 * - JWT validation via Supabase Auth
 * - Per-user daily quotas (100 requests/day)
 * - API key protection (never exposed to client)
 * - Usage logging for cost tracking and analytics
 * 
 * Usage:
 * POST /firebase-ai-proxy
 * Headers:
 *   Authorization: Bearer <supabase-jwt>
 * Body:
 *   { messages: [...], model: "gemini-3-flash" }
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { Redis } from "https://esm.sh/@upstash/redis@1.28.0";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const googleApiKey = Deno.env.get("GOOGLE_API_KEY")!; // Google AI Studio API key
const upstashUrl = Deno.env.get("UPSTASH_REDIS_URL");
const upstashToken = Deno.env.get("UPSTASH_REDIS_TOKEN");

// Use anon key instead of service role key for proper JWT validation
// The anon key supports ES256 algorithm used by Supabase Auth
const supabase = createClient(supabaseUrl, supabaseAnonKey);
// Redis is optional - only initialize if credentials are provided
const redis = (upstashUrl && upstashToken)
  ? new Redis({ url: upstashUrl, token: upstashToken })
  : null;

// CORS headers for Flutter web client
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // 1. Validate Supabase JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing auth token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.error("Auth error:", authError);
      return new Response(
        JSON.stringify({ error: "Invalid auth token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`Request from user: ${user.id}`);

    // 2. Rate limiting (per-user quota: 100 requests/day)
    if (redis) {
      const today = new Date().toISOString().slice(0, 10);
      const rateLimitKey = `firebase_ai_quota:${user.id}:${today}`;
      const currentUsage = await redis.incr(rateLimitKey);
      await redis.expire(rateLimitKey, 86400); // 24 hour TTL

      if (currentUsage > 100) {
        return new Response(
          JSON.stringify({
            error: "Quota exceeded",
            message: "Daily limit of 100 requests reached. Try again tomorrow."
          }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // 3. Parse request body
    const { messages, model = "gemini-3-flash-preview" } = await req.json();

    if (!messages || !Array.isArray(messages)) {
      return new Response(
        JSON.stringify({ error: "Invalid request: 'messages' must be an array" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`Calling Google AI Studio API with model: ${model}`);

    // 4. Call Google AI Studio API with streaming
    const startTime = Date.now();
    const aiStudioResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?key=${googleApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ 
          contents: messages,
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 8192,
          }
        }),
      }
    );

    if (!aiStudioResponse.ok) {
      const errorText = await aiStudioResponse.text();
      console.error("Google AI Studio error:", errorText);
      return new Response(
        JSON.stringify({ error: "AI API error", details: errorText }),
        { status: aiStudioResponse.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Stream response back to client in SSE format and collect tokens for logging
    let inputTokens = 0;
    let outputTokens = 0;

    const stream = new ReadableStream({
      async start(controller) {
        const reader = aiStudioResponse.body!.getReader();
        const decoder = new TextDecoder();
        const encoder = new TextEncoder();
        let buffer = "";

        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            const chunk = decoder.decode(value, { stream: true });
            buffer += chunk;

            // Google AI Studio returns chunks with format: [chunk1, chunk2, ...]
            // where the JSON array is streamed piece by piece
            // We need to extract complete JSON objects from the stream

            // Try to find complete JSON objects in buffer
            // Look for pattern: {...}
            let bracketCount = 0;
            let objectStart = -1;
            let inString = false;
            let escapeNext = false;

            for (let i = 0; i < buffer.length; i++) {
              const char = buffer[i];

              if (escapeNext) {
                escapeNext = false;
                continue;
              }

              if (char === '\\') {
                escapeNext = true;
                continue;
              }

              if (char === '"' && !escapeNext) {
                inString = !inString;
                continue;
              }

              if (inString) continue;

              if (char === '{') {
                if (bracketCount === 0) {
                  objectStart = i;
                }
                bracketCount++;
              } else if (char === '}') {
                bracketCount--;
                if (bracketCount === 0 && objectStart !== -1) {
                  // Found a complete object
                  const jsonStr = buffer.substring(objectStart, i + 1);
                  try {
                    const parsed = JSON.parse(jsonStr);

                    // Extract usage metadata if present
                    if (parsed.usageMetadata) {
                      inputTokens = parsed.usageMetadata.promptTokenCount || 0;
                      outputTokens = parsed.usageMetadata.candidatesTokenCount || 0;
                    }

                    // Send the chunk to client in SSE format
                    const sseMessage = `data: ${JSON.stringify(parsed)}\n\n`;
                    controller.enqueue(encoder.encode(sseMessage));
                  } catch (e) {
                    console.error("Failed to parse object:", jsonStr.substring(0, 100), e);
                  }

                  // Remove processed part from buffer
                  buffer = buffer.substring(i + 1);
                  i = -1; // Reset index as we modified buffer
                  objectStart = -1;
                }
              }
            }
          }

          // 6. Save to ai_usage_logs
          const latency = Date.now() - startTime;
          // Pricing for Gemini 2.0 Flash: $0.075/M input, $0.30/M output
          const costUsd = (inputTokens * 0.075 + outputTokens * 0.30) / 1_000_000;

          await supabase.from("ai_usage_logs").insert({
            user_id: user.id,
            provider: "firebase_ai",
            model,
            input_tokens: inputTokens,
            output_tokens: outputTokens,
            cost_usd: costUsd,
            latency_ms: latency,
          });

          console.log(`Request completed: ${inputTokens} input tokens, ${outputTokens} output tokens, ${latency}ms`);
          controller.close();
        } catch (error) {
          console.error("Stream error:", error);
          controller.error(error);
        }
      },
    });

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
      },
    });

  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

