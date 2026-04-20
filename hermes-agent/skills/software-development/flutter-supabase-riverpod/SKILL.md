---
name: flutter-supabase-riverpod
description: Best practices and boilerplate for integrating Supabase with Flutter using Riverpod.
category: software-development
---

# Flutter + Supabase + Riverpod Integration

This skill provides a robust architectural pattern for building local-first or cloud-synced Flutter apps using Supabase for the backend and Riverpod for state management.

## 1. Project Structure
```text
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart    # Supabase URL/Anon Key
│   └── utils/
│       └── logger.dart           # Logging configuration
├── data/
│   ├── providers/
│   │   └── supabase_provider.dart # Global Supabase client
│   └── services/
│       └── storage_service.dart   # File upload/download
└── features/
    └── auth/
        ├── providers/
        │   └── auth_provider.dart # Auth state & logic
        └── screens/
            └── login_screen.dart  # UI for authentication
```

## 2. Key Boilerplate

### Supabase Provider (`lib/data/providers/supabase_provider.dart`)
```dart
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

@riverpod
User? supabaseUser(Ref ref) => ref.watch(supabaseClientProvider).auth.currentUser;

@riverpod
Stream<AuthState> authStateChanges(Ref ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange;
```

### Auth Provider (`lib/features/auth/providers/auth_provider.dart`)
```dart
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  Future<AuthStateData> build() async {
    final client = ref.watch(supabaseClientProvider);
    ref.listen(authStateChangesProvider, (prev, next) {
      next.whenData((data) => _handleAuthChange(data));
    });
    return AuthStateData(user: client.auth.currentUser, session: client.auth.currentSession);
  }

  void _handleAuthChange(supabase.AuthState authState) {
    // Update state based on signedIn, signedOut, etc.
  }
}
```

## 3. Lessons Learned & Pitfalls

### Environment Secrets
*   **Protected .env**: In many agent environments, `.env` is a protected file. **Do NOT attempt to use `patch` or `write_file` on `.env` directly.**
*   **Workaround**: Provide a `.env.example` file and instruct the user to copy it manually to `.env`.

### Code Generation
*   After adding Riverpod annotations or Supabase models, always run:
    `dart run build_runner build --delete-conflicting-outputs`

### Database Triggers
*   Always create a `public.users` table in PostgreSQL to store extended profile data.
*   Use a PostgreSQL trigger to automatically create a `public.users` record when a new user signs up in `auth.users`.

## 4. Hybrid Migration Pattern (Drizzle + Supabase)

For projects that require advanced database schema management beyond basic SQL, use **Drizzle ORM** in a standalone Node.js directory:

- **Location**: `supabase/db/`
- **Setup**: Node.js project with `drizzle-orm`, `drizzle-kit`, and `pg`.
- **Schema**: `supabase/db/schema.ts` as the single source of truth for the database.
- **Workflow**:
  1.  Define schema in TypeScript.
  2.  Run `npx drizzle-kit generate` to create SQL migrations.
  3.  Run a migration script (`migrate.ts`) using the Supabase direct connection URL (Port 5432).
- **Orchestration**: Use a root `Makefile` to unify `flutter` and `supabase/db` commands (e.g., `make db-migrate`, `make flutter-build`).
