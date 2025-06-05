#!/bin/bash

set -e

echo "🧹 Deleting existing clusters (if any)..."
kind delete clusters -A || true

echo "🛠️ Creating 'master' cluster..."
kind create cluster --config clusters/kind-master.yaml

echo "🛠️ Creating 'slave' cluster..."
kind create cluster --config clusters/kind-slave.yaml

echo "🌐 Installing ingress-nginx in 'master'..."
kubectl config use-context kind-master
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/kind/deploy.yaml

echo "⌛ Waiting for ingress-nginx to be ready in 'master'..."
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "🚀 Deploying sample app in 'master'..."
kubectl apply -f app-deploy.yaml

echo "🌐 Installing ingress-nginx in 'slave'..."
kubectl config use-context kind-slave
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.6/deploy/static/provider/kind/deploy.yaml

echo "⌛ Waiting for ingress-nginx to be ready in 'slave'..."
kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "🚀 Deploying sample app in 'slave'..."
kubectl apply -f app-deploy.yaml

echo ""
echo "✅ Clusters and apps deployed successfully."
echo "🌍 Access your apps at:"
echo "  ▶ http://localhost:8080/ (master)"
echo "  ▶ http://localhost:8081/ (slave)"
