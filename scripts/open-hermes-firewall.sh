#!/bin/bash
# Open firewall for Hermes Agent port 8642
# Usage: ./open-hermes-firewall.sh <droplet-ip> [ssh-user]

DROPLET_IP="${1:-}"
SSH_USER="${2:-root}"

if [ -z "$DROPLET_IP" ]; then
    echo "Usage: $0 <droplet-ip> [ssh-user]"
    exit 1
fi

echo "Opening port 8642 on DigitalOcean droplet..."
echo "Droplet: ${DROPLET_IP}"
echo ""

ssh ${SSH_USER}@${DROPLET_IP} << 'EOF'
echo "Current UFW status:"
ufw status 2>/dev/null || echo "UFW not available"

echo ""
echo "Opening port 8642..."
ufw allow 8642/tcp 2>/dev/null || echo "Could not open port (may need sudo)"

echo ""
echo "Updated UFW status:"
ufw status 2>/dev/null || true
EOF

echo ""
echo "Done! Port 8642 should now be accessible."