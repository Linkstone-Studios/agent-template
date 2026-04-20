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
# Required
API_SERVER_KEY=your-secure-api-key-here
GOOGLE_API_KEY=your-google-api-key

# Optional
OPENAI_API_KEY=your-openai-key
ANTHROPIC_API_KEY=your-anthropic-key
```

## Scaling

For production, consider:
- Using a load balancer in front of multiple droplets
- Setting up automated backups via DigitalOcean
- Using Spaces for file storage
- Adding monitoring via DigitalOcean's built-in monitoring