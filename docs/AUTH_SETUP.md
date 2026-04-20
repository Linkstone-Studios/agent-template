# Authentication Setup Guide

This guide explains how to set up per-user authentication across all AI providers.

## Overview

The template uses **Supabase Edge Functions** as authentication proxies for all AI providers:

- **hermes-proxy**: Validates user JWT, forwards to Hermes Agent with user context
- **firebase-ai-proxy**: Validates user JWT, streams from Google AI Studio

Both proxies:
1. Validate the user's Supabase JWT token
2. Extract user information (ID, email)
3. Forward requests with user context headers
4. **Support streaming responses** (Server-Sent Events)
5. Log usage per user for analytics and billing

## Architecture

```
Flutter App (JWT) → Supabase Edge Function → AI Provider
                         ↓
                    Validates JWT
                    Extracts user info
                    Adds headers:
                      - X-User-ID
                      - X-User-Email  
                      - X-Supabase-Token
```

## Setup Steps

### 1. Configure Supabase Project

```bash
# Get your credentials from https://supabase.com/dashboard
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
```

Add these to your root `.env` file.

### 2. Apply Database Migrations

```bash
cd supabase/db
npm install
npm run db:migrate
```

This creates all necessary tables with Row Level Security enabled.

### 3. Deploy Edge Functions

```bash
# Install Supabase CLI if needed
brew install supabase/tap/supabase

# Link to your project
supabase link --project-ref your-project-ref

# Deploy both proxies
supabase functions deploy hermes-proxy
supabase functions deploy firebase-ai-proxy
```

### 4. Configure Edge Function Secrets

```bash
# For Hermes proxy
supabase secrets set HERMES_BASE_URL=http://your-droplet-ip:8642
supabase secrets set HERMES_API_PASSWORD=your-api-server-key

# For Firebase AI proxy
supabase secrets set GOOGLE_API_KEY=your-google-api-key

# Optional: Rate limiting (recommended for production)
supabase secrets set UPSTASH_REDIS_URL=your-redis-url
supabase secrets set UPSTASH_REDIS_TOKEN=your-redis-token

# Optional: Skip subscription checks during development
supabase secrets set SKIP_SUBSCRIPTION_CHECK=true
```

### 5. Deploy Hermes Agent to DigitalOcean

```bash
# Create droplet or use existing server
cd nemoclaw/config/droplet
./provision.sh <droplet-ip> root

# Deploy Hermes
cd ../../deploy
./deploy.sh <droplet-ip>

# SSH into droplet and configure .env
ssh root@<droplet-ip>
cd /app/nemoclaw/app/hermes-agent
nano .env
```

Add to Hermes `.env`:
```env
API_SERVER_KEY=your-secure-password
GOOGLE_API_KEY=your-google-api-key

# Supabase integration (for user-authenticated tools)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Restart Hermes:
```bash
docker compose restart
```

### 6. Configure Flutter App

Update `flutter/.env`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
AI_PROVIDER=hermes  # or firebase_ai
```

### 7. Test Authentication

```bash
# In Flutter app, sign in a test user
# Then send a chat message

# Check logs in Supabase Edge Function
supabase functions logs hermes-proxy --tail

# Should see:
# "User authenticated: <user-id>"
# "Request from user: <user-id>"
```

## Using User Context in Hermes Tools

When Hermes tools need to perform operations on behalf of the user:

```python
import os
from supabase import create_client

def get_user_data():
    # These headers are set by the hermes-proxy Edge Function
    user_id = os.environ.get('X_USER_ID')
    user_email = os.environ.get('X_USER_EMAIL')
    user_token = os.environ.get('X_SUPABASE_TOKEN')
    
    # Create authenticated Supabase client
    supabase = create_client(
        os.environ.get('SUPABASE_URL'),
        user_token  # User's JWT, not anon key
    )
    
    # Query respects Row Level Security
    conversations = supabase.table('conversations') \
        .select('*') \
        .eq('user_id', user_id) \
        .execute()
    
    return conversations.data
```

See `hermes-agent/skills/devops/supabase-auth/SKILL.md` for more examples.

## Security Best Practices

1. **Never expose service role key to clients** - Only use in Edge Functions and Hermes backend
2. **Always use user's JWT for RLS operations** - Don't bypass RLS unless necessary
3. **Validate JWT on every request** - Done automatically by Edge Functions
4. **Enable Row Level Security** - Already enabled in migrations
5. **Use rate limiting in production** - Configure Upstash Redis
6. **Monitor usage logs** - Track costs and potential abuse
7. **Set subscription checks** - Prevent unlimited usage

## Troubleshooting

### "Invalid authentication token"
- Check that Flutter app is sending JWT in Authorization header
- Verify user is signed in before making AI requests
- Check Supabase project URL and anon key are correct

### "Subscription inactive"
- Set `SKIP_SUBSCRIPTION_CHECK=true` for testing
- Or add subscription records to database for test users

### Hermes tools can't access Supabase
- Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` in Hermes .env
- Check that hermes-proxy is passing headers correctly
- Verify user token is being forwarded in `X-Supabase-Token` header

### Firebase AI proxy errors
- Check `GOOGLE_API_KEY` is set in Supabase secrets
- Verify API key has access to Gemini models
- Check rate limits aren't exceeded

## Next Steps

- Set up subscription management (see `supabase/db/schema.ts`)
- Configure A/B testing with Firebase Remote Config
- Add analytics tracking for provider usage
- Set up production rate limiting with Upstash

