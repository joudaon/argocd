#!/bin/bash

set -e

CLUSTER_NAME="slave"
KUBECONFIG_FILE="slave-kubeconfig.yaml"

echo "📦 Exporting kubeconfig for cluster '$CLUSTER_NAME'..."
kind export kubeconfig --name "$CLUSTER_NAME" --kubeconfig "$KUBECONFIG_FILE"

echo "🔍 Getting Docker IP of $CLUSTER_NAME-control-plane..."
CONTAINER_NAME="${CLUSTER_NAME}-control-plane"
CONTAINER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME")

if [[ -z "$CONTAINER_IP" ]]; then
  echo "❌ Could not get container IP for $CONTAINER_NAME"
  exit 1
fi

echo "✏️ Patching kubeconfig to use IP $CONTAINER_IP..."
# Replace the server line
sed -i.bak -E "s|https://127.0.0.1:[0-9]+|https://${CONTAINER_IP}:6443|" "$KUBECONFIG_FILE"

echo "🚀 Adding cluster to ArgoCD using the patched kubeconfig..."
argocd cluster add --kubeconfig "$KUBECONFIG_FILE" "kind-${CLUSTER_NAME}"

echo "✅ Done! You can verify with:"
echo "   argocd cluster list"