#!/bin/bash
# Fix Hermes Agent API server configuration
# Usage: ./fix-hermes-api.sh <droplet-ip> [ssh-user]

DROPLET_IP="${1:-}"
SSH_USER="${2:-root}"

if [ -z "$DROPLET_IP" ]; then
    echo "Usage: $0 <droplet-ip> [ssh-user]"
    exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Fixing Hermes Agent API Configuration ===${NC}\n"

# Check if .env exists and has API key
echo "Checking current configuration on remote server..."
ssh ${SSH_USER}@${DROPLET_IP} << 'EOF'
cd /app/nemoclaw/app/hermes-agent

if [ -f .env ]; then
    echo "Current .env exists"
    if grep -q "GOOGLE_API_KEY=your" .env || grep -q "GOOGLE_API_KEY=$" .env; then
        echo -e "${YELLOW}⚠️  GOOGLE_API_KEY appears to be a placeholder${NC}"
    elif grep -q "GOOGLE_API_KEY=" .env; then
        echo -e "${GREEN}✓ GOOGLE_API_KEY appears to be set${NC}"
    else
        echo -e "${YELLOW}⚠️  GOOGLE_API_KEY not found in .env${NC}"
    fi
else
    echo -e "${RED}✗ .env file not found${NC}"
fi

echo ""
echo "Container status:"
docker compose ps 2>/dev/null || echo "Not running"
EOF

echo ""
echo -e "${YELLOW}To manually fix .env on the droplet:${NC}"
echo -e "ssh ${SSH_USER}@${DROPLET_IP}"
echo -e "cd /app/nemoclaw/app/hermes-agent && nano .env"
echo ""
echo -e "Required changes:"
echo -e "  - GOOGLE_API_KEY=your_actual_key"
echo -e "  - API_SERVER_KEY=your_secure_password"