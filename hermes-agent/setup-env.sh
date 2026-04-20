#!/bin/bash
# Helper script to set up the .env file on the DigitalOcean droplet

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Hermes Agent Environment Setup ===${NC}\n"

# Check if .env already exists
if [ -f .env ]; then
    echo -e "${YELLOW}Warning: .env file already exists!${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting without changes."
        exit 0
    fi
    echo "Backing up existing .env to .env.backup..."
    cp .env .env.backup
fi

# Copy from example
if [ ! -f .env.example ]; then
    echo -e "${RED}Error: .env.example not found!${NC}"
    exit 1
fi

cp .env.example .env
echo -e "${GREEN}✓ Created .env from .env.example${NC}\n"

# Function to prompt for API key
prompt_key() {
    local var_name=$1
    local description=$2
    local required=$3
    
    echo -e "${YELLOW}${description}${NC}"
    read -p "Enter ${var_name} (or press Enter to skip): " value
    
    if [ -n "$value" ]; then
        # Escape special characters for sed
        escaped_value=$(echo "$value" | sed 's/[&/\]/\\&/g')
        sed -i.tmp "s|^${var_name}=.*|${var_name}=${escaped_value}|" .env
        rm -f .env.tmp
        echo -e "${GREEN}✓ Set ${var_name}${NC}\n"
    elif [ "$required" = "true" ]; then
        echo -e "${RED}Warning: ${var_name} is required for the agent to work!${NC}\n"
    else
        echo -e "Skipped ${var_name}\n"
    fi
}

echo "=== Configure Inference Providers (at least one required) ==="
prompt_key "GOOGLE_API_KEY" "Google AI Studio API key for Gemini models" "false"
prompt_key "ANTHROPIC_API_KEY" "Anthropic API key for Claude models" "false"
prompt_key "OPENAI_API_KEY" "OpenAI API key" "false"
prompt_key "OPENROUTER_API_KEY" "OpenRouter API key for multiple models" "false"

echo "=== Configure Optional Tools ==="
prompt_key "EXA_API_KEY" "Exa API key for search" "false"
prompt_key "TAVILY_API_KEY" "Tavily API key for search" "false"
prompt_key "FIRECRAWL_API_KEY" "Firecrawl API key for web scraping" "false"

echo "=== Configure API Server ==="
echo -e "${YELLOW}API Server Password (recommended for security)${NC}"
read -s -p "Enter API_SERVER_PASSWORD (or press Enter to skip): " api_password
echo
if [ -n "$api_password" ]; then
    escaped_password=$(echo "$api_password" | sed 's/[&/\]/\\&/g')
    sed -i.tmp "s|^API_SERVER_PASSWORD=.*|API_SERVER_PASSWORD=${escaped_password}|" .env
    rm -f .env.tmp
    echo -e "${GREEN}✓ Set API_SERVER_PASSWORD${NC}\n"
else
    echo -e "${YELLOW}Warning: No password set. API will be accessible without authentication!${NC}\n"
fi

echo "=== Configure Supabase (Optional) ==="
prompt_key "SUPABASE_URL" "Supabase URL for backend" "false"
prompt_key "SUPABASE_ANON_KEY" "Supabase anonymous key" "false"

echo -e "\n${GREEN}=== Setup Complete! ===${NC}"
echo -e "Configuration saved to .env\n"

# Check if at least one inference provider is set
if ! grep -q "^GOOGLE_API_KEY=.\+" .env && \
   ! grep -q "^ANTHROPIC_API_KEY=.\+" .env && \
   ! grep -q "^OPENAI_API_KEY=.\+" .env && \
   ! grep -q "^OPENROUTER_API_KEY=.\+" .env; then
    echo -e "${RED}⚠ WARNING: No inference provider API key configured!${NC}"
    echo -e "${RED}The agent will not work without at least one of:${NC}"
    echo -e "${RED}- GOOGLE_API_KEY (for Gemini models)${NC}"
    echo -e "${RED}- ANTHROPIC_API_KEY${NC}"
    echo -e "${RED}- OPENAI_API_KEY${NC}"
    echo -e "${RED}- OPENROUTER_API_KEY${NC}\n"
    echo -e "You can edit .env manually to add these keys.\n"
else
    echo -e "${GREEN}✓ At least one inference provider configured${NC}\n"
fi

echo "To restart the Hermes Agent with new settings, run:"
echo -e "${YELLOW}docker compose restart${NC}\n"

