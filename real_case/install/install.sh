#!/bin/bash

## Set virtualbox as default driver
minikube config set driver virtualbox

## Start Minikube
echo "--> Instaling minikube argocd-cluster"
minikube start --addons=dashboard --addons=metrics-server --addons=ingress --addons=registry --cpus=2 --memory=8gb -p argocd-cluster

## Install argocd
echo "---> Installing argocd"
kubectl create namespace argocd
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
helm repo add argo https://argoproj.github.io/argo-helm
helm install argo-cd argo/argo-cd -f argocd_values.yaml --namespace argocd --create-namespace --wait 
kubectl expose deployment argo-cd-argocd-server --type=NodePort --name=argo-cd-argocd-service --namespace=argocd
sleep 30s

## Install External Secrets Operator (https://github.com/external-secrets/external-secrets)(https://github.com/hashicorp/vault-helm/issues/17)
echo "---> Installing External Secrets Operator"
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --wait

## Install Argo Rollouts
echo "---> Installing Argo Rollouts"
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

## Install Argo CD Image Updater (https://argocd-image-updater.readthedocs.io/en/stable/) Installed with argocd
# echo "---> Installing Argo CD Image Updater"
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml

# ## Download argocd cli (uncomment if argocd cli not installed)
# VERSION="v2.6.6" # Select desired TAG from https://github.com/argoproj/argo-cd/releases
# curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
# sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
# rm argocd-linux-amd64

## Get credentials
echo "---> Installation finished!"
CREDFILENAME=credentials.txt
NODEPORT=$(kubectl get service argo-cd-argocd-service --namespace=argocd -ojsonpath='{.spec.ports[0].nodePort}')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "argocd URL --> $(minikube ip -p argocd-cluster):$NODEPORT" >> $CREDFILENAME
echo "argocd username --> admin" >> $CREDFILENAME
echo "argocd password --> $ARGOCD_PASSWORD" >> $CREDFILENAME

## Start Minikube dev-cluster
echo "--> Instaling minikube dev-cluster"
minikube start --cpus=2 --memory=4gb -p dev-cluster

## Start Minikube pre-cluster
echo "--> Instaling minikube pre-cluster"
minikube start --cpus=2 --memory=4gb -p pre-cluster

## Go back to argocd-cluster
echo "--> Switching context to argocd-cluster"
minikube profile argocd-cluster

## Adding dev/pre-cluster to argocd
echo "--> Logging into argocd cluster"
argocd login $(minikube ip -p argocd-cluster):$NODEPORT --username admin --password $ARGOCD_PASSWORD --insecure 
echo "--> Adding dev-cluster into argocd"
argocd cluster add dev-cluster --yes
echo "--> Adding pre-cluster into argocd"
argocd cluster add pre-cluster --yes
