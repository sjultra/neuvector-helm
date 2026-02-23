#!/usr/bin/env bash
# Remove all NeuVector resources from the current Kubernetes cluster.
#
# Usage:
#   ./scripts/cleanup-neuvector.sh
#   KUBECONFIG=kubeconfig.yml ./scripts/cleanup-neuvector.sh
#
# Steps: delete Fleet GitRepos -> uninstall Helm releases -> delete namespace -> delete CRDs

set -e

NAMESPACE="${NEUVECTOR_NAMESPACE:-cattle-neuvector-system}"
FLEET_NAMESPACE="${FLEET_NAMESPACE:-fleet-default}"

echo "=== NeuVector cleanup (namespace: $NAMESPACE) ==="

# 1. Remove Fleet GitRepos that deploy NeuVector (so Fleet stops reconciling)
echo ""
echo "1. Removing Fleet GitRepos that deploy NeuVector..."
for name in neuvector-scanner neuvector; do
  if kubectl get gitrepo -n "$FLEET_NAMESPACE" "$name" &>/dev/null; then
    kubectl delete gitrepo -n "$FLEET_NAMESPACE" "$name" --ignore-not-found --wait=false
    echo "   Deleted GitRepo: $name"
  else
    echo "   GitRepo $name not found (skip)"
  fi
done

# 2. Uninstall Helm releases in the NeuVector namespace
echo ""
echo "2. Uninstalling Helm releases in $NAMESPACE..."
for release in neuvector neuvector-scanner; do
  if helm status "$release" -n "$NAMESPACE" &>/dev/null; then
    helm uninstall "$release" -n "$NAMESPACE" --wait
    echo "   Uninstalled release: $release"
  else
    echo "   Release $release not found (skip)"
  fi
done

# 3. Delete the NeuVector namespace (removes any remaining resources)
echo ""
echo "3. Deleting namespace $NAMESPACE..."
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
  kubectl delete namespace "$NAMESPACE" --ignore-not-found --timeout=120s
  echo "   Namespace $NAMESPACE deleted."
else
  echo "   Namespace $NAMESPACE not found (skip)"
fi

# 3b. Remove cluster-scoped RBAC that might reference NeuVector
echo ""
echo "3b. Removing NeuVector ClusterRoles and ClusterRoleBindings..."
kubectl get clusterrole,clusterrolebinding -o name 2>/dev/null | grep -i neuvector | while read -r res; do
  kubectl delete "$res" --ignore-not-found --timeout=30s
  echo "   Deleted: $res"
done

# 4. Remove NeuVector CRDs (cluster-scoped)
echo ""
echo "4. Removing NeuVector CRDs..."
for crd in \
  nvadmissioncontrolsecurityrules.neuvector.com \
  nvclustersecurityrules.neuvector.com \
  nvgroupdefinitions.neuvector.com \
  nvsecurityrules.neuvector.com; do
  if kubectl get crd "$crd" &>/dev/null; then
    kubectl delete crd "$crd" --ignore-not-found --timeout=60s
    echo "   Deleted CRD: $crd"
  fi
done

# Delete any other CRDs with 'neuvector' in the name (e.g. from different chart versions)
for crd in $(kubectl get crd -o name 2>/dev/null | grep -i neuvector || true); do
  kubectl delete "$crd" --ignore-not-found --timeout=60s
  echo "   Deleted CRD: $crd"
done

# List any remaining CRDs with neuvector in the name
echo ""
echo "   Checking for any remaining NeuVector CRDs..."
kubectl get crd 2>/dev/null | grep -i neuvector || true

echo ""
echo "=== NeuVector cleanup finished ==="
