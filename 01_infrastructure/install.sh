#!/bin/bash

## Set docker as default driver
minikube config set driver docker

## Start Minikube
minikube start --addons=dashboard --addons=metrics-server --addons=ingress --addons=registry --cpus=4 --memory=8gb

## Install argocd
echo "---> Installing argocd"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl expose deployment argocd-server --type=NodePort --name=argocd-service --namespace=argocd
sleep 30s

## Install External Secrets Operator (https://github.com/external-secrets/external-secrets)(https://github.com/hashicorp/vault-helm/issues/17)
echo "---> Installing External Secrets Operator"
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --wait

## Install Argo Rollouts
echo "---> Installing Argo Rollouts"
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

## Install Argo CD Image Updater (https://argocd-image-updater.readthedocs.io/en/stable/)
echo "---> Installing Argo CD Image Updater"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml

# ## Install applicationset (currently included in argocd)
# echo "---> Installing applicationset"
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/applicationset/v0.4.1/manifests/install.yaml

# ## Install Argo CD Notifications (https://argocd-notifications.readthedocs.io/en/stable/) (currently included in argocd)
# echo "---> Installing Argo CD Notifications"
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-notifications/release-1.0/manifests/install.yaml

# ## Download argocd cli
# VERSION="v2.6.6" # Select desired TAG from https://github.com/argoproj/argo-cd/releases
# curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
# sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
# rm argocd-linux-amd64

## Get credentials
echo "---> Installation finished!"
NODEPORT=$(kubectl get service argocd-service --namespace=argocd -ojsonpath='{.spec.ports[0].nodePort}')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "argocd URL --> $(minikube ip):$NODEPORT"
echo "argocd username --> admin"
echo "argocd password --> $ARGOCD_PASSWORD"
