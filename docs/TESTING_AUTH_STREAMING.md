# Testing Authentication & Streaming

This guide helps you verify that the authentication and streaming implementation works correctly.

## Prerequisites

1. Supabase Edge Functions deployed
2. Hermes Agent running on DigitalOcean
3. User account created in Supabase Auth
4. Valid JWT token from authenticated user

## Testing Hermes Proxy

### 1. Test Non-Streaming Request

```bash
# Get a JWT token (from Flutter app or Supabase dashboard)
export JWT_TOKEN="your-jwt-token-here"
export SUPABASE_URL="https://your-project.supabase.co"

# Test non-streaming chat
curl -X POST "${SUPABASE_URL}/functions/v1/hermes-proxy" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-3-flash-preview",
    "messages": [
      {"role": "user", "content": "Say hello in 5 words"}
    ],
    "stream": false
  }'
```

**Expected Response:**
```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "model": "gemini-3-flash-preview",
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Hello! How can I help?"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 8,
    "total_tokens": 18
  }
}
```

### 2. Test Streaming Request

```bash
# Test streaming chat
curl -X POST "${SUPABASE_URL}/functions/v1/hermes-proxy" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -N \
  -d '{
    "model": "gemini-3-flash-preview",
    "messages": [
      {"role": "user", "content": "Count to 5 slowly"}
    ],
    "stream": true
  }'
```

**Expected Response (Server-Sent Events):**
```
data: {"id":"chatcmpl-...","object":"chat.completion.chunk","choices":[{"delta":{"content":"1"}}]}

data: {"id":"chatcmpl-...","object":"chat.completion.chunk","choices":[{"delta":{"content":"..."}}]}

data: {"id":"chatcmpl-...","object":"chat.completion.chunk","choices":[{"delta":{"content":"2"}}]}

data: [DONE]
```

### 3. Verify User Context Passed to Hermes

Check Hermes logs to confirm user context headers:

```bash
# SSH into your droplet
ssh root@your-droplet-ip

# View Hermes logs
cd /app/nemoclaw/app/hermes-agent
docker compose logs -f
```

Look for:
- `X-User-ID: <user-uuid>`
- `X-User-Email: <user-email>`
- `X-Supabase-Token: <jwt-token>`

### 4. Verify Usage Logging

```sql
-- Check Supabase database for usage logs
SELECT * FROM ai_usage_logs 
WHERE provider = 'hermes' 
ORDER BY created_at DESC 
LIMIT 10;
```

**Expected columns:**
- `user_id`: Your user UUID
- `provider`: 'hermes'
- `model`: 'gemini-3-flash-preview'
- `input_tokens`: Number (for non-streaming) or NULL (for streaming)
- `output_tokens`: Number (for non-streaming) or NULL (for streaming)
- `latency_ms`: Response time in milliseconds

## Testing Firebase AI Proxy

### 1. Test Streaming Request

```bash
curl -X POST "${SUPABASE_URL}/functions/v1/firebase-ai-proxy" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -N \
  -d '{
    "model": "gemini-3-flash-preview",
    "messages": [
      {"role": "user", "parts": [{"text": "Hello, world!"}]}
    ]
  }'
```

**Expected Response (Server-Sent Events):**
```
data: {"candidates":[{"content":{"parts":[{"text":"Hello"}]}}]}

data: {"candidates":[{"content":{"parts":[{"text":"!"}]}}]}

data: {"candidates":[{"content":{"parts":[{"text":" How"}]}}],"usageMetadata":{"promptTokenCount":5,"candidatesTokenCount":15}}
```

### 2. Verify Rate Limiting (if Upstash Redis configured)

```bash
# Make 101 requests rapidly
for i in {1..101}; do
  curl -X POST "${SUPABASE_URL}/functions/v1/firebase-ai-proxy" \
    -H "Authorization: Bearer ${JWT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"model":"gemini-3-flash-preview","messages":[{"role":"user","parts":[{"text":"Hi"}]}]}' &
done
wait
```

**Expected:** After 100 requests, you should receive:
```json
{
  "error": "Quota exceeded",
  "message": "Daily limit of 100 requests reached. Try again tomorrow."
}
```

## Testing User Context in Hermes Tools

### 1. Create Test Tool

Create `hermes-agent/skills/test/test_user_context.py`:

```python
import os
from supabase import create_client

def test_user_context():
    user_id = os.environ.get('X_USER_ID')
    user_email = os.environ.get('X_USER_EMAIL')
    token = os.environ.get('X_SUPABASE_TOKEN')
    
    print(f"User ID: {user_id}")
    print(f"User Email: {user_email}")
    print(f"Token: {token[:20]}..." if token else "No token")
    
    # Test Supabase query
    supabase = create_client(
        os.environ.get('SUPABASE_URL'),
        token
    )
    
    result = supabase.table('users').select('*').eq('id', user_id).execute()
    print(f"User data: {result.data}")

if __name__ == '__main__':
    test_user_context()
```

### 2. Call Tool via Chat

Send a chat message:
```
"Can you run the test_user_context tool and show me the results?"
```

**Expected output in response:**
```
User ID: <your-user-uuid>
User Email: <your-email>
Token: eyJhbGciOiJIUzI1NiI...
User data: [{'id': '<uuid>', 'email': '<email>', ...}]
```

## Common Issues

### "Invalid authentication token"
- **Cause**: JWT expired or invalid
- **Fix**: Generate a new JWT token from Supabase

### "No streaming response"
- **Cause**: `stream: false` or not set
- **Fix**: Set `"stream": true` in request body

### "User context headers missing in Hermes"
- **Cause**: Hermes called directly, not via proxy
- **Fix**: Always call via `/functions/v1/hermes-proxy`, never directly to droplet IP

### "Rate limit error immediately"
- **Cause**: Redis quota already hit
- **Fix**: Wait 24 hours or clear Redis key manually

### "No usage logs in database"
- **Cause**: Database permissions or table doesn't exist
- **Fix**: Run migrations: `cd supabase/db && npm run db:migrate`

## Success Criteria

✅ Non-streaming requests return complete JSON responses  
✅ Streaming requests return Server-Sent Events format  
✅ User context headers visible in Hermes logs  
✅ Usage logged to `ai_usage_logs` table with user_id  
✅ Hermes tools can query user-specific data  
✅ Rate limiting enforces quotas (if configured)  
✅ Both providers work identically from client perspective  

## Next Steps

Once all tests pass:
1. Integrate into Flutter app
2. Test with real user accounts
3. Monitor usage analytics
4. Configure production rate limits
5. Set up subscription enforcement

