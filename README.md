# Agent Template

A full-stack AI agent project template with Flutter app, Hermes agent, Supabase backend, and DigitalOcean deployment support.

## What's Included

```
├── flutter/           # Flutter mobile/web app with Riverpod & Firebase
├── hermes-agent/      # Hermes Agent (NousResearch) with skills
├── supabase/
│   └── db/           # Drizzle ORM schema + migrations
├── nemoclaw/          # DigitalOcean deployment config
├── scripts/          # Utility scripts
├── docs/             # Documentation
├── AGENTS.md         # AI agent instructions
└── Makefile          # Dev commands
```

## Quick Start

### 1. Clone & Customize

```bash
# Copy the template
cp -r agent-template my-new-project
cd my-new-project

# Remove git history (starts fresh)
rm -rf .git
git init
```

### 2. Configure Credentials

```bash
# Flutter
cd flutter
cp .env.example .env
# Edit .env with your Supabase + Firebase credentials

# Hermes Agent
cd ../hermes-agent
cp .env.example .env
# Edit .env with your API keys (Google, OpenAI, etc.)
```

### 3. Set Up Backend

```bash
cd ..
make setup                    # Install all dependencies
make db-migrate              # Apply database migrations
make db-gen-dart             # Generate Flutter models
```

### 4. Run Locally

```bash
# Flutter app
make flutter-run

# Hermes Agent (in another terminal)
cd hermes-agent
docker compose up -d
```

## Project Structure

### `flutter/`
- Flutter app with Shadcn UI, Riverpod state management
- Firebase integration (Auth, Analytics, Remote Config, App Check)
- Supabase integration (Postgres, Auth, Edge Functions)
- AI chat providers (Hermes + Firebase AI) with A/B testing support
- **Per-user authentication** - All AI requests include user's Supabase JWT

### `hermes-agent/`
- Hermes Agent with configurable personalities
- Docker Compose setup for easy deployment
- Pre-installed skills in `skills/` directory
- OpenAI-compatible API at port 8642

### `supabase/db/`
- Drizzle ORM for type-safe database management
- Migrations in `migrations/` directory
- Schema in `schema.ts` (source of truth)
- **Row Level Security (RLS)** - User data protected by JWT validation

### `supabase/functions/`
- **hermes-proxy** - Validates JWT, forwards to Hermes with user context
- **firebase-ai-proxy** - Validates JWT, streams from Google AI Studio
- Both proxies pass user authentication to enable per-user operations

### `nemoclaw/`
- DigitalOcean deployment scripts
- Droplet provisioning automation
- Deploy/sync/rollback scripts

## Common Commands

```bash
# Development
make help                    # Show all commands
make setup                   # Install dependencies
make flutter-run            # Run Flutter app
make flutter-build          # Run build_runner

# Database
make db-generate            # Generate migration
make db-migrate             # Apply migrations
make db-studio             # Open Drizzle Studio
make db-gen-dart           # Generate Dart models

# Agent
make agent-up              # Start Hermes via Docker
make agent-down            # Stop Hermes
make agent-logs            # View logs

# Deployment (see nemoclaw/README.md for details)
nemoclaw/deploy/deploy.sh <droplet-ip>
```

## Customizing for Your Project

1. **Update `AGENTS.md`** — Replace the generic mission with your project's purpose
2. **Update `hermes-agent/SOUL.md`** — Set your agent's personality
3. **Update `supabase/db/schema.ts`** — Define your data model
4. **Update `flutter/lib/main.dart`** — Change app name/theme
5. **Update `docs/BUSINESS_IDEA.md`** — Document your business logic

## Deployment

### DigitalOcean

```bash
# Provision a new droplet
nemoclaw/config/droplet/provision.sh <droplet-ip> root

# Deploy the app
nemoclaw/deploy/deploy.sh <droplet-ip>
```

### Other Platforms

The Hermes Agent runs in Docker, so it can be deployed anywhere:
- AWS EC2, Google Cloud, Azure
- Railway, Render, Fly.io
- Any server with Docker installed

## Environment Variables

See `.env.example` for all required variables.

**Key configurations:**
- Root `.env` - Supabase, Hermes endpoint, AI provider keys
- `flutter/.env` - Supabase URL and anon key
- `hermes-agent/.env` - API key, AI providers, Supabase credentials
- Edge Function secrets - Set via `supabase secrets set`

**Quick setup:**
```bash
# Copy example files
cp .env.example .env
cp flutter/.env.example flutter/.env
cp hermes-agent/.env.example hermes-agent/.env

# Edit with your credentials
nano .env
```

For detailed authentication and deployment setup, see: **[`docs/AUTH_SETUP.md`](docs/AUTH_SETUP.md)**

## Next Steps

- Read `docs/BUSINESS_IDEA.md` and replace with your project idea
- Run `make flutter-run` to see the app
- Explore `hermes-agent/skills/` to see available agent capabilities
- Check `AGENTS.md` to understand how AI agents should work on this codebase