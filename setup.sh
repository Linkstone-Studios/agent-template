#!/bin/bash
# Template Setup Script
# Run this after copying the template to get everything configured

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_NAME="agent-template"

echo -e "${GREEN}=== ${TEMPLATE_NAME} Setup ===${NC}\n"

# Check if we're in a template directory
if [ ! -f "AGENTS.md" ] || [ ! -d "flutter" ] || [ ! -d "hermes-agent" ]; then
    echo -e "${RED}Error: This script should be run from the template root directory${NC}"
    exit 1
fi

# Step 1: Ask for project name
echo -e "${YELLOW}Step 1: Project Name${NC}"
read -p "Enter your project name (no spaces, use hyphens): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-my-agent-project}
echo -e "Project name: ${PROJECT_NAME}\n"

# Step 2: Create .env files from examples
echo -e "${YELLOW}Step 2: Creating .env files${NC}"

if [ ! -f "flutter/.env" ] && [ -f "flutter/.env.example" ]; then
    cp flutter/.env.example flutter/.env
    echo "✓ Created flutter/.env — please edit it with your credentials"
fi

if [ ! -f "hermes-agent/.env" ] && [ -f "hermes-agent/.env.example" ]; then
    cp hermes-agent/.env.example hermes-agent/.env
    echo "✓ Created hermes-agent/.env — please edit it with your credentials"
fi

if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
    echo "✓ Created .env"
fi

echo ""

# Step 3: Install Flutter dependencies
echo -e "${YELLOW}Step 3: Installing Flutter dependencies${NC}"
if command -v flutter &> /dev/null; then
    cd flutter && flutter pub get && cd ..
    echo "✓ Flutter dependencies installed"
else
    echo -e "${YELLOW}⚠ Flutter not found — install from https://flutter.dev${NC}"
fi
echo ""

# Step 4: Install Supabase DB dependencies
echo -e "${YELLOW}Step 4: Installing Supabase DB dependencies${NC}"
if command -v npm &> /dev/null; then
    cd supabase/db && npm install && cd ../..
    echo "✓ Supabase DB dependencies installed"
else
    echo -e "${YELLOW}⚠ npm not found — install Node.js from https://nodejs.org${NC}"
fi
echo ""

# Step 5: Generate Dart models (requires DB to be set up first)
echo -e "${YELLOW}Step 5: Generate Dart models${NC}"
echo "Note: Run 'make db-gen-dart' AFTER setting up your Supabase database"
echo ""

# Step 6: Summary
echo -e "${GREEN}=== Setup Complete! ===${NC}\n"
echo "Next steps:"
echo ""
echo "1. ${YELLOW}Edit configuration files:${NC}"
echo "   - flutter/.env (Supabase + Firebase credentials)"
echo "   - hermes-agent/.env (API keys)"
echo ""
echo "2. ${YELLOW}Set up your database:${NC}"
echo "   - Create a Supabase project at https://supabase.com"
echo "   - Update supabase/db/schema.ts if needed"
echo "   - Run 'make db-migrate' to apply migrations"
echo "   - Run 'make db-gen-dart' to generate Dart models"
echo ""
echo "3. ${YELLOW}Run the app:${NC}"
echo "   - Flutter: make flutter-run"
echo "   - Agent: make agent-up (requires Docker)"
echo ""
echo "4. ${YELLOW}Deploy (when ready):${NC}"
echo "   - See nemoclaw/README.md for DigitalOcean deployment"
echo ""
echo -e "Good luck with ${PROJECT_NAME}! 🚀\n"