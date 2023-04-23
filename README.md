# argocd

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

