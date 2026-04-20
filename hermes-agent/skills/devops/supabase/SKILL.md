---
name: hybrid-flutter-supabase-drizzle
description: Orchestrate a hybrid Flutter app with a standalone Drizzle ORM migration layer for Supabase.
category: devops
---

# Hybrid Flutter + Supabase + Drizzle Architecture

This skill defines the workflow for managing a multi-layer project with a Flutter frontend, a Dockerized agent, and a standalone TypeScript/Drizzle migration layer for Supabase.

## Project Structure

```
.
├── client/              # Flutter app
├── hermes-agent/       # Dockerized agent / API server
├── supabase/
│   └── db/             # Drizzle migrations (Node.js)
│       ├── schema.ts   # Truth source for DB schema
│       ├── migrate.ts  # Migration script (using pg/tsx)
│       └── migrations/ # Generated SQL files
└── Makefile            # Root orchestration
```

## Setup & Orchestration (Makefile)

A root `Makefile` is used to unify the environments:

- `make setup`: Install dependencies for both Flutter and the Drizzle DB.
- `make flutter-build`: Generate Riverpod/Freezed code.
- `make agent-up`: Start the agent service.
- `make db-migrate`: Apply schema changes to Supabase.

## Database Management (Drizzle)

Instead of using the standard Supabase CLI migrations, use Drizzle for type-safe schema management.

### Configuration (`drizzle.config.ts`)
```typescript
import type { Config } from 'drizzle-kit'
import * as dotenv from 'dotenv'
dotenv.config({ path: '../../.env' })

export default {
  schema: `./schema.ts`,
  out: `./migrations`,
  dialect: `postgresql`,
  dbCredentials: { url: process.env.DATABASE_URL! }
} satisfies Config
```

### Applying Migrations (`migrate.ts`)
```typescript
import { drizzle } from 'drizzle-orm/node-postgres'
import { migrate } from 'drizzle-orm/node-postgres/migrator'
import { Pool } from 'pg'
// ... (pool setup with DATABASE_URL)
await migrate(db, { migrationsFolder: `migrations` })
```

## Flutter Integration

- **Environment**: Share a single `.env` at the root or under `client/` for `DATABASE_URL` and `SUPABASE_URL`.
- **Initialization**: Initialize `Supabase.initialize()` in `main.dart` with Anon key and URL.
- **Provider Pattern**: Use Riverpod generators for `supabaseClientProvider` and `authStateProvider`.

## Best Practices
- **Shared Schema**: Keep `supabase/db/schema.ts` as the single source of truth for the database structure.
- **Direct Connection**: Use the Supabase Direct Connection URL (port 5432) for migrations, and the API URL (port 443) for the Flutter app.
- **Code Gen**: Always run `build_runner` after modifying providers or data models in Flutter.
