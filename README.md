Kubernetes GitOps — Cluster
===========================

## Clusters environment

| Cluster name  | Description |
| ------------- | ------------- |
| Kind | Local/Dev environment with KinD. |
| Lab  | Pre-production environment. |
| Prod | Production environment.|

## Startup local dev cluster

### Pre-requisites

* [Docker Desktop](https://www.docker.com/products/docker-desktop)
* [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
* [Flux](https://toolkit.fluxcd.io/get-started/)

### Running the cluster

Create a GitHub Token and export
```
export GITHUB_USER=username
export GITHUB_TOKEN=github-token
```

Install the cluster
```
make
```

Wait for reconciliation (resources being synchronized with git) or force it
```
make reconcile-cluster
```

## Verify the deployment & access

Two workflow-demo pods are deployed into the kind namespace
```
~ kubectl get pods -n kind
NAME                           READY   STATUS    RESTARTS   AGE
podinfo-f478b8c7-ckxqq         1/1     Running   0          117s
podinfo-f478b8c7-x2jgl         1/1     Running   0          117s
```

The cluster is exposed on port 80 & 443 locally, and can be accessed with `https://localhost/`.
