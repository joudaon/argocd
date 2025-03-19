#!/bin/bash

K8S_VERSION=v1.29.0
ARGOCD_VERSION=7.6.5

## Start Kind Cluster
echo "--> Instaling Kind argocd-cluster"
kind create cluster --config argocd-cluster.yaml

# Install nginx ingress
echo "--> Installing nginx ingress"
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
sleep 60s

## Install argocd
echo "---> Installing argocd"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -f argocd_values.yaml --namespace argocd --version $ARGOCD_VERSION --create-namespace --wait 
sleep 30s

# # Bootstrap argo apps
echo "--> Bootstrapping argo applications"
kubectl apply -f ../argocd/bootstrap.yaml

## Get credentials
echo "---> Installation finished!"
CREDFILENAME=credentials.txt
# NODEPORT=$(kubectl get service argo-argocd-server --namespace=argocd -ojsonpath='{.spec.ports[0].nodePort}')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "argocd URL --> argocd.myorg.com" > $CREDFILENAME
echo "argocd username --> admin" >> $CREDFILENAME
echo "argocd password --> $ARGOCD_PASSWORD" >> $CREDFILENAME

## Start Kind dev-cluster
echo "--> Instaling kind dev-cluster"
kind create cluster --config dev-cluster.yaml
kubectl cluster-info --context kind-dev-cluster

# Go back to argocd-cluster
# echo "--> Switching context to argocd-cluster"
# kubectl config use-context kind-argocd-cluster

## Adding dev/pre-cluster to argocd
echo "--> Logging into argocd cluster"
argocd login argocd.myorg.com --username admin --password $ARGOCD_PASSWORD --insecure --grpc-web
echo "--> Getting docker ip"
DEVCLUSTERIP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' dev-cluster-control-plane)
kubectl config set-cluster kind-dev-cluster --server=https://$DEVCLUSTERIP:6443
echo "- Docker IP: $DEVCLUSTERIP"
kubectl cluster-info --context kind-dev-cluster
echo "--> Adding dev-cluster into argocd"
# argocd cluster add kind-dev-cluster --annotation environment=dev --label environment=dev --label enable_external-secrets=true --label enable_keda=true --label enable_kube-state-metrics=false --label enable_reloader=true --label enable_kyverno=false --label enable_rancher=true --yes --grpc-web
argocd cluster add kind-dev-cluster --annotation environment=dev --label environment=dev --label enable_external-secrets=true --label enable_keda=true --label enable_kube-state-metrics=false --label enable_reloader=true --label enable_kyverno=false --insecure --yes --upsert --grpc-web


## INFO
echo "--> INSTALLATION FINISHED"
echo "-------------------------"
echo "--> Add 127.0.0.1 argocd.myorg.com to /etc/hosts file"
echo "--> Go to argocd.myorg.com"