#!/bin/bash

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# 🎯 Initial configuration
# ─────────────────────────────────────────────────────────────
CLUSTER_MASTER="master"
CLUSTER_SLAVE="slave"
KUBECONFIG_SLAVE="slave-kubeconfig.yaml"
ARGOCD_VERSION="9.2.4" # https://artifacthub.io/packages/helm/argo/argo-cd
ARGOCD_DOMAIN="argocd.myorg.com"
GRAFANA_DOMAIN="grafana.myorg.com"
PROMETHEUS_DOMAIN="prometheus.myorg.com"
ARGOCD_PORT="8443"
CREDENTIALS_FILE="credentials.txt"

# ─────────────────────────────────────────────────────────────
# 🧹 Delete existing clusters (if any)
# ─────────────────────────────────────────────────────────────
echo "🧹 Deleting existing clusters (if any)..."
kind delete clusters -A || true

# ─────────────────────────────────────────────────────────────
# 🔧 Create master and slave clusters
# ─────────────────────────────────────────────────────────────
echo "🛠️ Creating '$CLUSTER_MASTER' cluster..."
kind create cluster --config clusters/kind-${CLUSTER_MASTER}.yaml

echo "🛠️ Creating '$CLUSTER_SLAVE' cluster..."
kind create cluster --config clusters/kind-${CLUSTER_SLAVE}.yaml

# ─────────────────────────────────────────────────────────────
# 🌐 Install ingress-nginx in both clusters
# ─────────────────────────────────────────────────────────────
for cluster in $CLUSTER_MASTER $CLUSTER_SLAVE; do
  echo "🌐 Installing ingress-nginx in '$cluster'..."
  kubectl config use-context kind-$cluster
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/kind/deploy.yaml

  echo "⏳ Waiting for ingress-nginx to be ready in '$cluster'..."
  kubectl wait --namespace ingress-nginx \
    --for=condition=Ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s

  # echo "🚀 Deploying sample app in '$cluster'..."
  # kubectl apply -f app-deploy.yaml
done

# ─────────────────────────────────────────────────────────────
# 🚀 Install ArgoCD in the master cluster
# ─────────────────────────────────────────────────────────────
echo "🚀 Installing ArgoCD in '$CLUSTER_MASTER'..."
kubectl config use-context kind-${CLUSTER_MASTER}
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -f argocd_values.yaml --namespace argocd --version $ARGOCD_VERSION --create-namespace --wait

# Give it a bit of time to settle
echo "⏱ Waiting a bit for ArgoCD components to fully initialize..."
sleep 30s

# ─────────────────────────────────────────────────────────────
# 🔐 Login to ArgoCD
# ─────────────────────────────────────────────────────────────
echo "🔐 Logging into ArgoCD..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login ${ARGOCD_DOMAIN}:${ARGOCD_PORT} --username admin --password $ARGOCD_PASSWORD --insecure --grpc-web

# ─────────────────────────────────────────────────────────────
# 🔗 Register the slave cluster in ArgoCD
# ─────────────────────────────────────────────────────────────
echo "🔗 Registering '$CLUSTER_SLAVE' cluster in ArgoCD..."

echo "📦 Exporting kubeconfig for '$CLUSTER_SLAVE'..."
kind export kubeconfig --name "$CLUSTER_SLAVE" --kubeconfig "$KUBECONFIG_SLAVE"

echo "🔍 Getting Docker IP of ${CLUSTER_SLAVE}-control-plane..."
CONTAINER_NAME="${CLUSTER_SLAVE}-control-plane"
CONTAINER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME")

if [[ -z "$CONTAINER_IP" ]]; then
  echo "❌ Could not get container IP for $CONTAINER_NAME"
  exit 1
fi

echo "✏️ Patching kubeconfig to use IP $CONTAINER_IP..."
sed -i.bak -E "s|https://127.0.0.1:[0-9]+|https://${CONTAINER_IP}:6443|" "$KUBECONFIG_SLAVE"

echo "🚀 Adding '$CLUSTER_SLAVE' to ArgoCD..."
argocd cluster add --kubeconfig "$KUBECONFIG_SLAVE" kind-${CLUSTER_SLAVE} -y

# ─────────────────────────────────────────────────────────────
# ✅ Wrap-up
# ─────────────────────────────────────────────────────────────
echo ""
echo "✅ Clusters and applications deployed successfully!"
echo ""
echo "🌐 Access your services:"
echo "  ▶ HTTP  (master) : http://localhost:8080/"
echo "  ▶ HTTPS (master) : https://localhost:8443/"
echo "  ▶ HTTP  (slave)  : http://localhost:8081/"
echo "  ▶ HTTPS (slave)  : https://localhost:8444/"
echo "  ▶ ArgoCD         : https://${ARGOCD_DOMAIN}:${ARGOCD_PORT}/"
echo ""

echo "💾 Saving ArgoCD / Grafana credentials to '${CREDENTIALS_FILE}'..."
rm -f $CREDENTIALS_FILE
{
  echo "ArgoCD URL       --> https://${ARGOCD_DOMAIN}:${ARGOCD_PORT}/"
  echo "ArgoCD User      --> admin"
  echo "ArgoCD Password  --> $ARGOCD_PASSWORD"
} >> $CREDENTIALS_FILE

echo "📁 Credentials saved in '${CREDENTIALS_FILE}'"
echo "🎉 All done!"
