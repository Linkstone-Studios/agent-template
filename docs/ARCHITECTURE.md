# Architecture

This document describes the high-level architecture of the agent template.

## Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Flutter App (with Supabase JWT)               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐  │
│  │   Auth      │  │   Chat      │  │   Analytics                 │  │
│  │ (Supabase)  │  │  (AI Prov.) │  │  (Firebase + Supabase)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────────┘  │
│         │                │                    │                       │
│         └────────────────┼────────────────────┘                       │
│                          │ (sends JWT in Authorization header)       │
│                          ▼                                            │
│              ┌───────────────────────┐                                │
│              │   Supabase Backend    │                                │
│              │  ┌────────────────┐   │                                │
│              │  │ Edge Functions │   │                                │
│              │  │ - hermes-proxy │   │  (validates JWT, extracts      │
│              │  │ - firebase-ai  │   │   user info, forwards with     │
│              │  └────────────────┘   │   X-User-ID, X-Supabase-Token) │
│              │  ┌────────────────┐   │                                │
│              │  │  Database      │   │                                │
│              │  │  + RLS Policies│   │                                │
│              │  └────────────────┘   │                                │
│              └───────────┬───────────┘                                │
└────────────────────────────┼───────────────────────────────────────────┘
                             │
                ┌────────────┴──────────────┐
                │                           │
                ▼                           ▼
┌────────────────────────────┐  ┌────────────────────────────┐
│   Hermes Agent             │  │   Firebase AI              │
│   (DigitalOcean/Docker)    │  │   (Google AI Studio)       │
│   - Receives user context  │  │   - Direct API calls       │
│   - Tool execution         │  │   - Streaming responses    │
│   - Supabase operations    │  │   - Token counting         │
│   - OpenAI-compatible API  │  │   - Cost tracking          │
└────────────────────────────┘  └────────────────────────────┘
```

## Authentication Flow

### Per-User Authentication

Every AI request includes the user's Supabase JWT token, ensuring:

1. **Identity Verification** - Only authenticated users can access AI services
2. **Row Level Security** - Database queries respect user permissions
3. **Usage Tracking** - All operations are logged per user
4. **Subscription Enforcement** - Optional subscription checks before allowing requests

**Request Flow:**
```
1. User signs in → Gets Supabase JWT
2. User sends chat → Includes JWT in Authorization header
3. Edge Function validates JWT → Extracts user.id, user.email
4. Edge Function forwards to AI → Adds X-User-ID, X-User-Email, X-Supabase-Token headers
5. AI provider (Hermes) receives → Tools can use user context for authenticated operations
6. Response returns → Usage logged to database with user_id
```

## Components

### Flutter App
- **State Management**: Riverpod
- **UI**: Shadcn Flutter (built on Flutter's Material)
- **Auth**: Firebase Auth (Google, Apple sign-in)
- **AI Providers**: Pluggable provider interface for Hermes or Firebase AI

### Supabase Backend
- **Database**: PostgreSQL with Drizzle ORM
- **Auth**: Built-in Supabase Auth
- **Edge Functions**: Serverless functions for API proxying
- **Storage**: File storage (avatars, uploads)

### Hermes Agent
- **Runtime**: Docker on DigitalOcean (or any Docker host)
- **API**: OpenAI-compatible at port 8642
- **Skills**: Pre-configured skill library in `hermes-agent/skills/`
- **Personalities**: Configurable via `hermes-agent/SOUL.md`

### Firebase AI (Alternative Provider)
- **API**: Google AI Studio via Edge Function proxy
- **Use case**: Fast, stateless Q&A
- **Security**: Rate limiting + JWT validation in Edge Function

## Data Flow

### Chat (via Hermes)
```
User → Flutter App → hermes-proxy (Edge Function) → Hermes Agent (DO)
                                                          │
                                                          ▼
                                                    Google AI Studio
                                                          │
                                                          ▼
                                                    Hermes Agent → hermes-proxy → Flutter App
```

### Chat (via Firebase AI)
```
User → Flutter App → firebase-ai-proxy (Edge Function) → Google AI Studio
                                                              │
                                                              ▼
                                                         firebase-ai-proxy → Flutter App
```

## Database Schema

See `supabase/db/schema.ts` for the full data model.

Key tables:
- `users` — User accounts (synced from Supabase Auth)
- `subscriptions` — Subscription status
- `conversations` — Chat sessions with provider metadata
- `chat_messages` — Individual messages
- `ai_usage_logs` — AI API usage tracking
- `prompt_templates` — Reusable system prompts

## Security

- **Row Level Security (RLS)**: Enabled on all user data tables
- **JWT Validation**: All Edge Functions validate Supabase JWT
- **User Context Passing**: AI providers receive user identity via headers
- **Rate Limiting**: Via Upstash Redis (optional, for production)
- **App Check**: Firebase App Check for mobile apps
- **API Key Protection**: Google API keys never exposed to client

## Tool Authentication in Hermes

Hermes tools can perform operations on behalf of the authenticated user:

### User Context Headers

When called via `hermes-proxy`, Hermes receives:
- `X-User-ID`: The authenticated user's Supabase user ID
- `X-User-Email`: The user's email address
- `X-Supabase-Token`: The original JWT token

### Example: Querying User Data

```python
# In a Hermes skill/tool
from supabase import create_client
import os

def get_user_conversations():
    """Fetch conversations for the authenticated user"""
    # User context automatically available from proxy headers
    user_id = os.environ.get('X_USER_ID')
    token = os.environ.get('X_SUPABASE_TOKEN')

    # Create Supabase client with user's token (respects RLS)
    supabase = create_client(
        os.environ.get('SUPABASE_URL'),
        token  # Use user's JWT, not anon key
    )

    # This query only returns the user's own conversations
    result = supabase.table('conversations') \
        .select('*') \
        .eq('user_id', user_id) \
        .execute()

    return result.data
```

See `hermes-agent/skills/devops/supabase-auth/SKILL.md` for complete documentation.

## Environment Variables

See `.env.example` files in each component directory.

---

Replace this diagram with your project's actual architecture.