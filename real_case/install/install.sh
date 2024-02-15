#!/bin/bash

## Set virtualbox as default driver
minikube config set driver virtualbox

## Start Minikube
echo "--> Instaling minikube argocd-cluster"
minikube start --addons=dashboard --addons=metrics-server --addons=ingress --addons=registry --cpus=2 --memory=6gb -p argocd-cluster
# minikube start --addons=ingress --cpus=2 --memory=8gb -p argocd-cluster
sleep 30s

# ## Create server certificates
# echo "--> Creating server certificates"
# openssl req -nodes -new -x509 -keyout server.key -out server.cert -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department CN=example.com"
# kubectl create ns argocd
# kubectl create secret tls ingress-tls --key server.key --cert server.cert --namespace=argocd
# sleep 30s

## Install argocd
echo "---> Installing argocd"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argo argo/argo-cd -f argocd_values.yaml --namespace argocd --version 6.0.14 --create-namespace --wait 
sleep 30s

# Bootstrap argo apps
echo "--> Bootstrapping argo applications"
kubectl apply -f ../argocd/bootstrap.yaml

## Get credentials
echo "---> Installation finished!"
CREDFILENAME=credentials.txt
# NODEPORT=$(kubectl get service argo-argocd-server --namespace=argocd -ojsonpath='{.spec.ports[0].nodePort}')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "argocd URL --> argocd.myorg.com" >> $CREDFILENAME
echo "argocd username --> admin" >> $CREDFILENAME
echo "argocd password --> $ARGOCD_PASSWORD" >> $CREDFILENAME

## Start Minikube dev-cluster
echo "--> Instaling minikube dev-cluster"
minikube start --addons=ingress --addons=metrics-server --cpus=2 --memory=6gb -p dev-cluster

## Start Minikube pre-cluster
echo "--> Instaling minikube pre-cluster"
minikube start --addons=ingress --addons=metrics-server --cpus=2 --memory=4gb -p pre-cluster

## Go back to argocd-cluster
echo "--> Switching context to argocd-cluster"
minikube profile argocd-cluster

## Sleep 1 minute to update etc/hosts file
echo "--> Update /etc/hosts file"
INGRESS_IP=$(kubectl get ingress -n argocd -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo "$INGRESS_IP argocd.myorg.com"
sleep 1m

## Adding dev/pre-cluster to argocd
echo "--> Logging into argocd cluster"
argocd login argocd.myorg.com --username admin --password $ARGOCD_PASSWORD --insecure --grpc-web
echo "--> Adding dev-cluster into argocd"
argocd cluster add dev-cluster --label environment=dev --label enable_external-secrets=true --label enable_keda=true --label enable_kube-state-metrics=false --label enable_reloader=true --label enable_kyverno=false --label enable_rancher=true --yes --grpc-web
echo "--> Adding pre-cluster into argocd"
argocd cluster add pre-cluster --label environment=pre --label enable_external-secrets=true --label enable_keda=true --label enable_kube-state-metrics=false --label enable_reloader=true --label enable_kyverno=false --yes --grpc-web
