#!/bin/bash
# Helper script to set Rancher URL in values files
# Usage: ./scripts/set-rancher-url.sh https://rancher.example.com

set -e

RANCHER_URL="${1:-}"

if [ -z "$RANCHER_URL" ]; then
  echo "Usage: $0 <rancher-url>"
  echo "Example: $0 https://rancher.example.com"
  exit 1
fi

# Update values/rancher-config.yaml
if [ -f "values/rancher-config.yaml" ]; then
  # Use sed to replace the URL (works with both http and https)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|url: \".*\"|url: \"$RANCHER_URL\"|g" values/rancher-config.yaml
  else
    # Linux
    sed -i "s|url: \".*\"|url: \"$RANCHER_URL\"|g" values/rancher-config.yaml
  fi
  echo "✓ Updated values/rancher-config.yaml with Rancher URL: $RANCHER_URL"
else
  echo "✗ values/rancher-config.yaml not found"
  exit 1
fi

# Optionally update fleet.yaml if it has empty values
if [ -f "fleet.yaml" ]; then
  echo ""
  echo "Note: You may also want to update fleet.yaml if you're using inline values"
  echo "Current fleet.yaml has empty URL values that can be set manually"
fi

echo ""
echo "Done! You can now use:"
echo "  - values/rancher-config.yaml with Helm: helm install -f values/rancher-config.yaml"
echo "  - Or reference it in Fleet configuration"

