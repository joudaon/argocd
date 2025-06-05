#!/bin/bash

kind delete cluster --name argocd-cluster
kind delete cluster --name dev-cluster