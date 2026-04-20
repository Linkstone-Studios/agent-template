# NemoClaw - DigitalOcean Deployment

This directory contains the configuration and deployment setup for running the agent template on DigitalOcean.

## Structure

```
nemoclaw/
├── app/                    # Application files that sync to the droplet
│   └── hermes-agent/       # Hermes Agent application
├── lib/                    # Shared libraries (empty for template)
├── config/                 # Configuration files
│   ├── droplet/            # Droplet provisioning scripts
│   ├── nginx/              # Nginx configuration (optional reverse proxy)
│   └── supervisor/         # Process supervisor config
├── deploy/                 # Deployment scripts
│   ├── deploy.sh           # Main deployment script
│   ├── sync.sh            # Sync app files to droplet
│   └── rollback.sh        # Rollback to previous version
└── README.md              # This file
```

## Quick Start

### 1. Create a DigitalOcean Droplet

```bash
# Create a droplet with Docker pre-installed
doctl compute droplet create agent-template \
  --region nyc \
  --size s-4vcpu-8gb \
  --image docker-20-04 \
  --ssh-keys <your-ssh-key-id> \
  --enable-monitoring
```

### 2. Deploy

```bash
cd nemoclaw/deploy
./deploy.sh <droplet-ip>
```

### 3. Verify

```bash
curl https://<droplet-ip>:8642/v1/models
```

## Configuration

### Environment Variables (in `hermes-agent/.env`)

```env
# Required: API Server password (generate with: openssl rand -base64 32)
API_SERVER_KEY=your-secure-api-key-here

# Required: At least one AI provider
GOOGLE_API_KEY=your-google-api-key

# Required: Supabase integration (for user authentication in tools)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Optional: Additional AI providers
OPENAI_API_KEY=your-openai-key
ANTHROPIC_API_KEY=your-anthropic-key

# Optional: Supabase admin operations (bypasses RLS)
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### Authentication Flow

This deployment works with Supabase Edge Functions to provide **per-user authentication**:

1. **Flutter App** → Sends request with user's Supabase JWT
2. **Supabase Edge Function** (`hermes-proxy`) → Validates JWT, extracts user info
3. **Hermes Agent** → Receives user context via headers:
   - `X-User-ID`: User's Supabase ID
   - `X-User-Email`: User's email
   - `X-Supabase-Token`: JWT for authenticated Supabase operations

This allows Hermes tools to:
- Query user-specific data (respecting Row Level Security)
- Save chat history to the user's account
- Track usage per user
- Enforce subscription limits

See `hermes-agent/skills/devops/supabase-auth/SKILL.md` for using user context in tools.

## Scaling

For production, consider:
- Using a load balancer in front of multiple droplets
- Setting up automated backups via DigitalOcean
- Using Spaces for file storage
- Adding monitoring via DigitalOcean's built-in monitoring