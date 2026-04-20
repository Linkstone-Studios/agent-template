#!/bin/bash
# Automated version bumping for Flutter app
# Usage: ./scripts/bump-version.sh [provider] [feature]
# Environment variables:
#   AI_PROVIDER: 'hermes' or 'firebase_ai' (default: hermes)
#   FEATURE_SUFFIX: feature suffix (default: basic)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VERSION_FILE="flutter/pubspec.yaml"

# Check if version file exists
if [ ! -f "$VERSION_FILE" ]; then
  echo -e "${RED}Error: $VERSION_FILE not found${NC}"
  exit 1
fi

# Parse current version
CURRENT_VERSION=$(grep "^version:" $VERSION_FILE | sed 's/version: //')

if [ -z "$CURRENT_VERSION" ]; then
  echo -e "${RED}Error: Could not parse current version from $VERSION_FILE${NC}"
  exit 1
fi

echo -e "${YELLOW}Current version: $CURRENT_VERSION${NC}"

# Split version into components
IFS='+' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
BASE_VERSION="${VERSION_PARTS[0]}"

# Extract build number from the second part (if exists)
if [ ${#VERSION_PARTS[@]} -gt 1 ]; then
  BUILD_NUMBER=$(echo "${VERSION_PARTS[1]}" | grep -o '^[0-9]*')
else
  BUILD_NUMBER="0"
fi

# Increment build number
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Get provider from environment, argument, or default
if [ -n "$1" ]; then
  PROVIDER="$1"
elif [ -n "$AI_PROVIDER" ]; then
  PROVIDER="$AI_PROVIDER"
else
  PROVIDER="hermes"
fi

# Validate provider
if [ "$PROVIDER" != "hermes" ] && [ "$PROVIDER" != "firebase_ai" ]; then
  echo -e "${RED}Error: Invalid provider '$PROVIDER'. Must be 'hermes' or 'firebase_ai'${NC}"
  exit 1
fi

# Get feature suffix from environment, argument, or default
if [ -n "$2" ]; then
  FEATURE="$2"
elif [ -n "$FEATURE_SUFFIX" ]; then
  FEATURE="$FEATURE_SUFFIX"
else
  FEATURE="basic"
fi

# Construct new version
NEW_VERSION="${BASE_VERSION}+${NEW_BUILD_NUMBER}-${PROVIDER}-${FEATURE}"

echo -e "${GREEN}New version: $NEW_VERSION${NC}"

# Update pubspec.yaml
# macOS requires -i '' for in-place sed, Linux doesn't
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" $VERSION_FILE
else
  # Linux
  sed -i "s/^version: .*/version: $NEW_VERSION/" $VERSION_FILE
fi

# Verify the update
UPDATED_VERSION=$(grep "^version:" $VERSION_FILE | sed 's/version: //')
if [ "$UPDATED_VERSION" != "$NEW_VERSION" ]; then
  echo -e "${RED}Error: Version update failed. Expected $NEW_VERSION, got $UPDATED_VERSION${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Version updated successfully in $VERSION_FILE${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  Base Version: $BASE_VERSION"
echo "  Build Number: $NEW_BUILD_NUMBER (was: $BUILD_NUMBER)"
echo "  Provider: $PROVIDER"
echo "  Feature: $FEATURE"
echo "  Full Version: $NEW_VERSION"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review the change: git diff $VERSION_FILE"
echo "  2. Commit the change: git add $VERSION_FILE && git commit -m 'chore: bump version to $NEW_VERSION'"
echo "  3. Build the app with this version"
echo ""
echo -e "${GREEN}Done!${NC}"

