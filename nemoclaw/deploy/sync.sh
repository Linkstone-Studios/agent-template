#!/bin/bash
# Sync local changes to the droplet (faster than full deploy)
# Usage: ./sync.sh <droplet-ip> [ssh-user]

DROPLET_IP=$1
SSH_USER=${2:-root}
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$DROPLET_IP" ]; then
    echo "Usage: $0 <droplet-ip> [ssh-user]"
    exit 1
fi

echo "Syncing to ${SSH_USER}@${DROPLET_IP}..."
rsync -avz --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='build/' \
  --exclude='.env' \
  --exclude='__pycache__' \
  ${PROJECT_DIR}/hermes-agent/ \
  ${SSH_USER}@${DROPLET_IP}:/app/nemoclaw/app/hermes-agent/

ssh ${SSH_USER}@${DROPLET_IP} "cd /app/nemoclaw/app/hermes-agent && docker compose restart"