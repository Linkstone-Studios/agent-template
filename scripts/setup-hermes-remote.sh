#!/bin/bash
# Script to set up Hermes Agent on DigitalOcean droplet
# Usage: ./setup-hermes-remote.sh <droplet-ip> [ssh-user]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Remote Hermes Agent Setup ===${NC}\n"

if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <droplet-ip> [ssh-user]${NC}"
    echo -e "Example: $0 192.168.1.100 root\n"
    exit 1
fi

DROPLET_IP=$1
SSH_USER=${2:-root}

echo -e "Connecting to ${YELLOW}${SSH_USER}@${DROPLET_IP}${NC}...\n"

# Test SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${SSH_USER}@${DROPLET_IP} "echo 'Connection successful'" 2>&1; then
    echo -e "\n${RED}Error: Cannot connect to ${DROPLET_IP}${NC}"
    echo -e "Make sure your SSH key is added to the droplet.\n"
    exit 1
fi

echo -e "${GREEN}✓ Connected to droplet${NC}\n"

# Run the setup
echo -e "Starting environment setup on remote server...\n"
ssh -t ${SSH_USER}@${DROPLET_IP} "cd /app/nemoclaw/app/hermes-agent && bash setup-env.sh" 2>/dev/null || true

echo -e "\n${GREEN}=== Setup Complete! ===${NC}\n"
echo -e "Next steps:"
echo -e "  1. Check status: ssh ${SSH_USER}@${DROPLET_IP} 'cd /app/nemoclaw/app/hermes-agent && docker compose ps'"
echo -e "  2. View logs: ssh ${SSH_USER}@${DROPLET_IP} 'cd /app/nemoclaw/app/hermes-agent && docker compose logs -f'"
echo -e "  3. Edit .env: ssh ${SSH_USER}@${DROPLET_IP} 'cd /app/nemoclaw/app/hermes-agent && nano .env'"