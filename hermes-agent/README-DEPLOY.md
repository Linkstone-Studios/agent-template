# Hermes Agent Deployment

## Docker Compose Setup

The agent runs via Docker Compose. Copy `.env.example` to `.env` and configure:

```bash
cp hermes-agent/.env.example hermes-agent/.env
```

Then start with:
```bash
docker-compose up -d
```

## Environment Variables

Key variables to set:
- `API_SERVER_KEY` — password for the agent's API server
- `GOOGLE_API_KEY` — for Gemini model access
- Any provider API keys you want to use

## Customizing

- **config.yaml** — main agent configuration
- **SOUL.md** — agent personality
- **skills/** — installed skills the agent can use
