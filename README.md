# argocd

## Deploy

1. Install minikube with argocd

```sh
./01_infrastructure/install.sh
```

## Approach 1

//TODO

## Approach 2

//TODO

## Approach 3

In this approach we will deploy 2 applications. The first application will deploy shared objects like `namespace` and the other application will deploy `application` specific resources.

1. Install minikube

```sh
./01_infrastructure/install.sh
```

2. Deploy 

```sh
kubectl apply -f 02_approach_3/argocd/root_app.yaml
```

## CLI deployment

1. Login into the cluster with argocd cli

```sh
argocd login $(minikube ip):$NODEPORT --username admin
```


2. Sync your app runing

```sh
./03_deployments/deploy_app.sh
```

## Usefull links

- [Git Generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-Git/)
- [How to create ArgoCD Applications Automatically using ApplicationSet? “Automation of GitOps”](https://amralaayassen.medium.com/how-to-create-argocd-applications-automatically-using-applicationset-automation-of-the-gitops-59455eaf4f72)
- [](https://www.buchatech.com/2022/08/how-to-set-the-application-reconciliation-timeout-in-argo-cd/)
- [](https://argo-cd.readthedocs.io/en/stable/operator-manual/health/ag)
- [Default timeout for 'argocd app wait' cli command](https://github.com/argoproj/argo-cd/discussions/10478)
- [Cluster add-ons examples](https://github.com/aws-samples/eks-blueprints-add-ons)
- [Deploying Prometheus and Grafana as Applications Using ArgoCD — Including Dashboards](https://dzone.com/articles/deploying-prometheus-and-grafana-as-applications-u)