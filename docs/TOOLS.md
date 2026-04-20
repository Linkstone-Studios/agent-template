# TOOLS.md - Tool & Service Configuration

_Use this file to document your project's tool and service configuration._

## External Services

### Supabase
- **URL**: https://supabase.com
- **Dashboard**: https://supabase.com/dashboard
- **Project Ref**: (find in Project Settings)
- **Database**: Direct connection on port `5432` (NOT `6543`)

### Firebase
- **Console**: https://console.firebase.google.com
- **Project ID**: (find in Project Settings)
- **Services used**: Auth, Analytics, Remote Config, App Check

### Google AI Studio
- **URL**: https://makersuite.google.com/app/apikey
- **API**: `generativelanguage.googleapis.com`
- **Model**: `gemini-3-flash-preview` (default)

## API Keys Needed

| Service | Key Name | Where to Get |
|---------|----------|--------------|
| Supabase | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Project Settings → API |
| Google | `GOOGLE_API_KEY` | AI Studio → API Key |
| Firebase | (auto-configured) | Firebase Console |

## Service Ports

| Service | Port | Notes |
|---------|------|-------|
| Hermes Agent API | 8642 | OpenAI-compatible |
| Hermes Gateway | 8000 | Web UI |
| Supabase (direct) | 5432 | Not the connection pooler! |

## Webhook/Callback URLs

When setting up external integrations, your callback URLs will be:

- **Supabase Edge Functions**: `https://your-project.supabase.co/functions/v1/function-name`
- **Firebase Hosting**: `https://your-project.web.app`

---

Replace this with your actual service configurations.