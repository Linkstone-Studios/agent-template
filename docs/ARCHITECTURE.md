# Architecture

This document describes the high-level architecture of the agent template.

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Auth      │  │   Chat      │  │   Analytics             │  │
│  │  (Firebase) │  │  (AI Prov.) │  │  (Firebase + Supabase)  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│         │                │                    │                   │
│         └────────────────┼────────────────────┘                   │
│                          │                                        │
│                    ┌─────┴─────┐                                  │
│                    │ Supabase  │                                  │
│                    │ (Backend) │                                  │
│                    └─────┬─────┘                                  │
└──────────────────────────┼──────────────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
┌─────────────────────────┐  ┌─────────────────────────┐
│   Hermes Agent           │  │   Firebase AI           │
│   (DigitalOcean/docker)  │  │   (Google AI Studio)    │
│   - Stateful             │  │   - Stateless           │
│   - Tool execution       │  │   - Fast                │
│   - OpenAI-compatible    │  │   - Simple              │
└─────────────────────────┘  └─────────────────────────┘
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
- **Rate Limiting**: Via Upstash Redis (optional, for production)
- **App Check**: Firebase App Check for mobile apps

## Environment Variables

See `.env.example` files in each component directory.

---

Replace this diagram with your project's actual architecture.