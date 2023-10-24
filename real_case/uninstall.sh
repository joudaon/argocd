#!/bin/bash

## delete clusters
minikube delete -p argocd-cluster
minikube delete -p dev-cluster
minikube delete -p pre-cluster