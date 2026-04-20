#!/bin/bash
# Test script for Hermes Chat functionality
# Usage: ./test-hermes-chat.sh [hermes-url] [api-key]

set -e

echo "🧪 Hermes Chat Test Script"
echo "=========================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

HERMES_URL="${1:-http://localhost:8642}"
API_KEY="${2:-}"

echo "Testing Hermes Agent at: ${HERMES_URL}"
echo ""

# Test 1: Check if endpoint is reachable
echo -e "${YELLOW}[1/4] Testing endpoint reachability...${NC}"
if curl -s --connect-timeout 5 "${HERMES_URL}/v1/models" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Endpoint is reachable${NC}"
else
    echo -e "${RED}✗ Cannot reach endpoint${NC}"
    echo -e "Make sure Hermes is running: docker compose up -d"
    exit 1
fi

# Test 2: Check models endpoint
echo -e "\n${YELLOW}[2/4] Checking models endpoint...${NC}"
MODELS_RESPONSE=$(curl -s "${HERMES_URL}/v1/models" 2>/dev/null || echo "error")
if echo "$MODELS_RESPONSE" | grep -q "models"; then
    echo -e "${GREEN}✓ Models endpoint working${NC}"
    echo "Available models:"
    echo "$MODELS_RESPONSE" | grep -o '"id":"[^"]*"' | head -5
else
    echo -e "${RED}✗ Models endpoint issue${NC}"
fi

# Test 3: Send a test message
echo -e "\n${YELLOW}[3/4] Sending test message...${NC}"
if [ -z "$API_KEY" ]; then
    echo -e "${YELLOW}⚠️  No API key provided, skipping chat test${NC}"
    echo "Run with API key: $0 <url> <api-key>"
else
    RESPONSE=$(curl -s -X POST "${HERMES_URL}/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${API_KEY}" \
        -d '{"model":"gemini-3-flash-preview","messages":[{"role":"user","content":"Hi! Say hello in 3 words."}],"max_tokens":50}' 2>/dev/null || echo "error")

    if echo "$RESPONSE" | grep -q "content"; then
        echo -e "${GREEN}✓ Chat working!${NC}"
        echo "Response: $(echo "$RESPONSE" | grep -o '"content":"[^"]*"' | head -1)"
    else
        echo -e "${RED}✗ Chat test failed${NC}"
        echo "Response: $RESPONSE"
    fi
fi

# Test 4: Verify streaming support
echo -e "\n${YELLOW}[4/4] Testing streaming...${NC}"
STREAM_TEST=$(curl -s -N -X POST "${HERMES_URL}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d '{"model":"gemini-3-flash-preview","messages":[{"role":"user","content":"Count to 3"}],"stream":true,"max_tokens":20}' 2>/dev/null | head -c 200 || echo "timeout")
if [ -n "$STREAM_TEST" ] && [ "$STREAM_TEST" != "timeout" ]; then
    echo -e "${GREEN}✓ Streaming supported${NC}"
else
    echo -e "${YELLOW}⚠️  Streaming may not be available${NC}"
fi

echo ""
echo -e "${GREEN}=== Test Complete ===${NC}"
echo ""
echo "Next steps:"
echo "  - Configure hermes-agent/.env with your API keys"
echo "  - Deploy to DigitalOcean: nemoclaw/deploy/deploy.sh <ip>"