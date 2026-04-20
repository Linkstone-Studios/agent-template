#!/bin/bash
# Diagnostic script for Hermes Agent

set -e

DROPLET_IP="${1:-}"
SSH_USER="${2:-root}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$DROPLET_IP" ]; then
    echo -e "${YELLOW}Usage: $0 <droplet-ip> [ssh-user]${NC}"
    exit 1
fi

echo -e "${BLUE}=== Hermes Agent Diagnostics ===${NC}\n"
echo -e "Droplet IP: ${DROPLET_IP}"
echo -e "SSH User: ${SSH_USER}\n"

# Test 1: Can we reach the droplet?
echo -e "${YELLOW}[1/6] Testing droplet connectivity...${NC}"
if ping -c 2 -W 2 ${DROPLET_IP} > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Droplet is reachable${NC}\n"
else
    echo -e "${RED}✗ Cannot ping droplet${NC}\n"
fi

# Test 2: Check SSH access
echo -e "${YELLOW}[2/6] Testing SSH access...${NC}"
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${SSH_USER}@${DROPLET_IP} "echo 'SSH OK'" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ SSH access working${NC}\n"
else
    echo -e "${RED}✗ Cannot SSH to droplet${NC}"
    exit 1
fi

# Test 3: Check Docker status
echo -e "${YELLOW}[3/6] Checking Docker installation...${NC}"
ssh ${SSH_USER}@${DROPLET_IP} << 'EOF'
if command -v docker &> /dev/null; then
    echo "✓ Docker is installed"
    docker --version
else
    echo "✗ Docker is NOT installed"
fi
EOF
echo ""

# Test 4: Check if files are deployed
echo -e "${YELLOW}[4/6] Checking if Hermes files are deployed...${NC}"
ssh ${SSH_USER}@${DROPLET_IP} << 'EOF'
if [ -d "/app/nemoclaw/app/hermes-agent" ]; then
    echo "✓ Hermes directory exists"
    ls -lah /app/nemoclaw/app/hermes-agent/ | head -10
else
    echo "✗ Hermes directory NOT found at /app/nemoclaw/app/hermes-agent"
fi
EOF
echo ""

# Test 5: Check Docker container status
echo -e "${YELLOW}[5/6] Checking Docker container status...${NC}"
ssh ${SSH_USER}@${DROPLET_IP} << 'EOF'
cd /app/nemoclaw/app/hermes-agent
echo "Container status:"
docker compose ps 2>/dev/null || echo "Docker compose not running"
echo ""
echo "Recent logs (last 20 lines):"
docker compose logs --tail=20 2>/dev/null || echo "No logs available"
EOF
echo ""

# Test 6: Check if port is listening
echo -e "${YELLOW}[6/6] Checking if port 8642 is listening...${NC}"
ssh ${SSH_USER}@${DROPLET_IP} << 'EOF'
if ss -tlnp | grep :8642 > /dev/null 2>&1; then
    echo "✓ Port 8642 is listening"
    ss -tlnp | grep :8642
else
    echo "✗ Port 8642 is NOT listening"
fi
EOF
echo ""

echo -e "${BLUE}=== Diagnostics Complete ===${NC}\n"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Deploy if needed: nemoclaw/deploy/deploy.sh ${DROPLET_IP} ${SSH_USER}"
echo -e "2. Check logs: ssh ${SSH_USER}@${DROPLET_IP} 'cd /app/nemoclaw/app/hermes-agent && docker compose logs -f'"
echo -e "3. Check .env: ssh ${SSH_USER}@${DROPLET_IP} 'cat /app/nemoclaw/app/hermes-agent/.env'"