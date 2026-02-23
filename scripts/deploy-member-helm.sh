#!/usr/bin/env bash
# Deploy NeuVector member to a downstream cluster (no Fleet).
# Usage: ./scripts/deploy-member-helm.sh <cluster-kubeconfig>
# Example: ./scripts/deploy-member-helm.sh /path/to/c-68tw8-kubeconfig

set -e
KUBECONFIG="${1:?Usage: $0 <path-to-cluster-kubeconfig>}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAMESPACE="${NEUVECTOR_NAMESPACE:-cattle-neuvector-system}"
RELEASE_NAME="${RELEASE_NAME:-neuvector-member}"

echo "=== Deploying NeuVector member (release: $RELEASE_NAME) ==="
echo "Kubeconfig: $KUBECONFIG"
echo "Namespace:  $NAMESPACE"
echo ""

# Use local chart from repo so no external fetch is needed
CHART_PATH="$REPO_ROOT/charts/neuvector/charts/core-2.8.3.tgz"
if [[ ! -f "$CHART_PATH" ]]; then
  echo "Chart not found at $CHART_PATH. Run: helm dependency update charts/neuvector"
  exit 1
fi

KUBECONFIG="$KUBECONFIG" helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
  -n "$NAMESPACE" \
  --create-namespace \
  -f "$REPO_ROOT/values/neuvector-member.yaml"

echo ""
echo "Done. Do one-time Join from this cluster's NeuVector UI (token from primary)."
