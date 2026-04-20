# Supabase Backend

This directory contains the Supabase backend configuration for the agent template.

## Structure

```
supabase/
├── db/                    # Database schema and migrations
│   ├── schema.ts          # Drizzle ORM schema (source of truth)
│   ├── drizzle.config.ts  # Drizzle configuration
│   ├── migrate.ts         # Migration runner
│   ├── package.json       # Node dependencies
│   ├── generate-dart-types.ts  # Dart model generator
│   └── migrations/        # SQL migrations (auto-generated)
├── functions/             # Supabase Edge Functions
│   ├── hermes-proxy/      # Proxy to Hermes Agent
│   └── firebase-ai-proxy/  # Proxy to Firebase AI
└── scripts/               # Utility scripts
    ├── create_analytics_views.sql
    └── user_auto_creation.sql
```

## Database Setup

### 1. Set up your Supabase project

1. Create a project at https://supabase.com
2. Get your project URL and anon key
3. Find your `DATABASE_URL` in Project Settings → Database

### 2. Configure environment

Create a `.env` file in the project root:
```env
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
SUPABASE_URL=https://[PROJECT-REF].supabase.co
SUPABASE_ANON_KEY=[ANON-KEY]
SUPABASE_SERVICE_ROLE_KEY=[SERVICE-ROLE-KEY]
```

### 3. Apply migrations

```bash
cd supabase/db
npm install
npm run db:migrate
```

### 4. Generate Flutter models

```bash
npm run gen:dart
```

## Schema Management

### Making changes

1. Edit `supabase/db/schema.ts` (the source of truth)
2. Generate migration:
   ```bash
   npm run db:generate
   ```
3. Review the generated SQL in `migrations/`
4. Apply:
   ```bash
   npm run db:migrate
   ```
5. Regenerate Dart models:
   ```bash
   npm run gen:dart
   ```
6. Commit both `schema.ts` and the migration file

### Key Tables

- `users` — User profiles (synced from Supabase Auth)
- `subscriptions` — Subscription status and plan info
- `conversations` — Chat sessions with AI providers
- `chat_messages` — Individual messages in conversations
- `ai_usage_logs` — AI API usage for analytics
- `prompt_templates` — Reusable system prompts

## Edge Functions

### hermes-proxy

Proxies requests to the Hermes Agent running on DigitalOcean.

**Environment variables:**
- `HERMES_BASE_URL` - URL of your Hermes droplet (default: `http://YOUR_DROPLET_IP:8642`)
- `HERMES_API_PASSWORD` - Password for Hermes API

### firebase-ai-proxy

Proxies requests to Google AI Studio (Firebase AI).

## Migrations

Migrations are managed by Drizzle ORM and stored in `db/migrations/`.

To reset and start fresh:
```bash
# Drop all tables (WARNING: destroys data!)
npm run db:push -- --force
```

## Useful Commands

```bash
# Open Drizzle Studio (visual database editor)
npm run db:studio

# Push schema without migrations
npm run db:push

# Generate migration from schema changes
npm run db:generate
```

## Documentation

- [Drizzle ORM Docs](https://orm.drizzle.team)
- [Supabase Docs](https://supabase.com/docs)
- [Supabase Edge Functions](https://supabase.com/docs/edge-functions)