#!/bin/bash

## Set virtualbox as default driver
minikube config set driver virtualbox

## Start Minikube
echo "--> Instaling minikube cluster-1"
minikube start --addons=dashboard --addons=metrics-server --addons=ingress --addons=registry --cpus=2 --memory=6gb -p cluster-1

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

# ## Download argocd cli (uncomment if argocd cli not installed)
# VERSION="v2.6.6" # Select desired TAG from https://github.com/argoproj/argo-cd/releases
# curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
# sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
# rm argocd-linux-amd64

## Get credentials
echo "---> Installation finished!"
NODEPORT=$(kubectl get service argocd-service --namespace=argocd -ojsonpath='{.spec.ports[0].nodePort}')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "argocd URL --> $(minikube ip -p cluster-1):$NODEPORT"
echo "argocd username --> admin"
echo "argocd password --> $ARGOCD_PASSWORD"

## Start Minikube
echo "--> Instaling minikube cluster-2"
minikube start --cpus=2 --memory=6gb -p cluster-2

## Go back to cluster-1
echo "--> Switching context to cluster-1"
minikube profile cluster-1

## Adding cluster-2 to argocd
echo "--> Logging into argocd cluster"
argocd login $(minikube ip -p cluster-1):$NODEPORT --username admin --password $ARGOCD_PASSWORD --insecure 
echo "--> Adding cluster-2 into argocd"
argocd cluster add cluster-2 --yes
