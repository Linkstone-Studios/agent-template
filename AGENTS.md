# Agent Instructions

This document provides critical guidance for AI agents working on this codebase.

## Business Mission

Replace this with your project's mission statement. What does this codebase do? Who is it for? What problems does it solve?

**Agent Rule**: All tasks must directly advance the project's goals as defined here.

## Database Management

### **IMPORTANT: Use Drizzle ORM ONLY**

This project uses **Drizzle ORM** for database schema management and migrations.

### Database Workflow

#### 1. Schema Changes
All schema changes must be made in the **TypeScript schema file**:

```
supabase/db/schema.ts
```

#### 2. Generate Migrations
```bash
cd supabase/db
npm run db:generate
```

#### 3. Apply Migrations
```bash
npm run db:migrate
```

#### 4. Commit Both Files
Always commit BOTH files together:
- `supabase/db/schema.ts` (schema changes)
- `supabase/db/migrations/000X_*.sql` (generated migration)

### DO NOT

- Create files in `supabase/migrations/`
- Write manual SQL migrations outside of Drizzle
- Edit the database directly without updating schema.ts

### Dart Type Generation

After changing the database schema, regenerate Dart models:

```bash
make db-gen-dart
```

Generated files go in `flutter/lib/data/models/generated/`.

## Key Principles

1. **Schema is Source of Truth** - Always edit `schema.ts` first
2. **Never Skip Migrations** - Even for small changes
3. **Review Before Apply** - Always check generated SQL
4. **Commit Schema + Migration Together** - Keep them in sync

---

**Last Updated:** 2026-04-19