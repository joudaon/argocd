# argocd

## Deploy

1. Install minikube with argocd

```sh
./01_infrastructure/install.sh
```

2. Login into the cluster with argocd cli

```sh
argocd login $(minikube ip):$NODEPORT --username admin
```

3. Create a project and application set

```sh
kubectl apply -f 02_applications/01_project.yaml
kubectl apply -f 02_applications/02_applicationset.yaml
```

4. Sync your app runing

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