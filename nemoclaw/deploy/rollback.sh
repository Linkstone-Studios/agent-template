#!/bin/bash
# Rollback to previous version
# Usage: ./rollback.sh <droplet-ip> [ssh-user]

DROPLET_IP=$1
SSH_USER=${2:-root}

if [ -z "$DROPLET_IP" ]; then
    echo "Usage: $0 <droplet-ip> [ssh-user]"
    exit 1
fi

echo "Rolling back on ${SSH_USER}@${DROPLET_IP}..."
ssh ${SSH_USER}@${DROPLET_IP} "cd /app/nemoclaw/app/hermes-agent && docker compose down && git stash && git checkout HEAD~1 && docker compose up -d --build"