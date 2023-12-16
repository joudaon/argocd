#!/bin/bash

## Set virtualbox as default driver
minikube config set driver virtualbox

## Start Minikube
echo "--> Instaling minikube argocd-cluster"
minikube start --addons=dashboard --addons=metrics-server --addons=ingress --addons=registry --cpus=2 --memory=8gb -p argocd-cluster

## Install argocd
echo "---> Installing argocd"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argo argo/argo-cd -f argocd_values.yaml --namespace argocd --version 5.51.6 --create-namespace --wait 
sleep 30s

## Bootstrap argo apps
echo "--> Bootstrapping argo applications"
kubectl apply -f ../argocd/bootstrap.yaml

## Get credentials
echo "---> Installation finished!"
CREDFILENAME=credentials.txt
NODEPORT=$(kubectl get service argo-argocd-server --namespace=argocd -ojsonpath='{.spec.ports[0].nodePort}')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "argocd URL --> $(minikube ip -p argocd-cluster):$NODEPORT" >> $CREDFILENAME
echo "argocd username --> admin" >> $CREDFILENAME
echo "argocd password --> $ARGOCD_PASSWORD" >> $CREDFILENAME

## Start Minikube dev-cluster
echo "--> Instaling minikube dev-cluster"
minikube start --addons=metrics-server --cpus=2 --memory=4gb -p dev-cluster

## Start Minikube pre-cluster
echo "--> Instaling minikube pre-cluster"
minikube start --addons=metrics-server --cpus=2 --memory=4gb -p pre-cluster

## Go back to argocd-cluster
echo "--> Switching context to argocd-cluster"
minikube profile argocd-cluster

## Adding dev/pre-cluster to argocd
echo "--> Logging into argocd cluster"
argocd login $(minikube ip -p argocd-cluster):$NODEPORT --username admin --password $ARGOCD_PASSWORD --insecure 
echo "--> Adding dev-cluster into argocd"
argocd cluster add dev-cluster --label environment=dev --label enable_external-secrets=true --label enable_keda=true --label enable_kube-state-metrics=true --label enable_kyverno=true --yes
echo "--> Adding pre-cluster into argocd"
argocd cluster add pre-cluster --label environment=pre --label enable_external-secrets=true --label enable_keda=true --label enable_kube-state-metrics=true --label enable_kyverno=true --yes
