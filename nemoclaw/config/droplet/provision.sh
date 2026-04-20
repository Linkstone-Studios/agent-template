#!/bin/bash
# Provision a new DigitalOcean droplet with Docker and basic setup
# Run this ONCE when creating a new droplet

set -e

DROPLET_IP=$1
SSH_USER=${2:-root}
DOMAIN=${3:-}

if [ -z "$DROPLET_IP" ]; then
    echo "Usage: $0 <droplet-ip> [ssh-user] [domain]"
    echo "Example: $0 192.168.1.100 root agent.example.com"
    exit 1
fi

echo "Provisioning droplet at ${DROPLET_IP}..."

# Wait for droplet to be ready
echo "Waiting for SSH to be available..."
sleep 10

# Test SSH
until ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${SSH_USER}@${DROPLET_IP} "echo 'OK'" 2>/dev/null; do
    echo "Waiting..."
    sleep 5
done

echo "Connected! Running setup..."

# Run setup commands via SSH
ssh ${SSH_USER}@${DROPLET_IP} << 'EOF'
set -e

echo "Updating system..."
apt-get update -qq
apt-get upgrade -y -qq

echo "Installing prerequisites..."
apt-get install -y -qq curl git ufw fail2ban

echo "Setting up UFW firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8642/tcp  # Hermes API
ufw --force enable

echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh
usermod -aG docker root

echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Creating app directory..."
mkdir -p /app/nemoclaw/app /app/nemoclaw/config /app/nemoclaw/data /app/nemoclaw/logs

echo "Enabling Docker on boot..."
systemctl enable docker

echo "Provisioning complete!"
docker --version
docker-compose --version
EOF

echo ""
echo "✅ Droplet provisioned successfully!"
echo ""
echo "Next: Deploy the application with:"
echo "  ./deploy/deploy.sh ${DROPLET_IP} ${SSH_USER}"