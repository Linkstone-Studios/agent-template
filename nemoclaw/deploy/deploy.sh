#!/bin/bash
# NemoClaw Deployment Script
# Deploys the agent template to a DigitalOcean droplet

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== NemoClaw Deployment ===${NC}\n"

# Check arguments
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <droplet-ip> [ssh-user]${NC}"
    echo -e "Example: $0 192.168.1.100 root\n"
    exit 1
fi

DROPLET_IP=$1
SSH_USER=${2:-root}
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo -e "Deploying to ${YELLOW}${SSH_USER}@${DROPLET_IP}${NC}...\n"

# Test SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${SSH_USER}@${DROPLET_IP} "echo 'Connection successful'" 2>&1; then
    echo -e "\n${RED}Error: Cannot connect to ${DROPLET_IP}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Connected${NC}\n"

# Create remote directory structure
echo "Creating remote directory structure..."
ssh ${SSH_USER}@${DROPLET_IP} "mkdir -p /app/nemoclaw/{app,config,data,logs}"

# Sync app files
echo "Syncing application files..."
rsync -avz --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='build/' \
  --exclude='.env' \
  ${PROJECT_DIR}/hermes-agent/ \
  ${SSH_USER}@${DROPLET_IP}:/app/nemoclaw/app/hermes-agent/

# Sync config files
echo "Syncing configuration files..."
rsync -avz --delete \
  ${PROJECT_DIR}/nemoclaw/config/ \
  ${SSH_USER}@${DROPLET_IP}:/app/nemoclaw/config/ 2>/dev/null || true

# Build and start the container
echo "Building and starting Docker container..."
ssh ${SSH_USER}@${DROPLET_IP} << 'EOF'
cd /app/nemoclaw/app/hermes-agent

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo "⚠️  Please edit .env and add your API keys!"
fi

# Start the container
docker compose up -d --build

# Show status
echo ""
echo "Container status:"
docker compose ps
EOF

echo -e "\n${GREEN}=== Deployment Complete! ===${NC}\n"
echo -e "Next steps:"
echo -e "  1. Edit .env on the droplet: ssh ${SSH_USER}@${DROPLET_IP} 'cd /app/nemoclaw/app/hermes-agent && nano .env'"
echo -e "  2. Check logs: ssh ${SSH_USER}@${DROPLET_IP} 'cd /app/nemoclaw/app/hermes-agent && docker compose logs -f'"
echo -e "  3. Test the API: curl https://${DROPLET_IP}:8642/v1/models"