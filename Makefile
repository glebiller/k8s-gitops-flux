FLUX_COMPONENTS?=source-controller,kustomize-controller,helm-controller

all: check-env create-cluster install-flux create-source create-kustomization

.PHONY: check-env
check-env:
ifndef GITHUB_USER
	$(error GITHUB_USER is undefined)
endif
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN is undefined)
endif

.PHONY: create-cluster
create-cluster:
	@if ! kind get clusters | grep -q kind; then \
		kind create cluster --config e2e/kind.yaml;\
	fi

.PHONY: install-flux
install-flux: create-cluster
	flux install --namespace flux-system --components $(FLUX_COMPONENTS)

.PHONY: create-source
create-source: check-env install-flux
	flux create source git k8s-gitops-flux-cluster --url=https://github.com/glebiller/k8s-gitops-flux-cluster.git --branch=main --username=${GITHUB_USER} --password=${GITHUB_TOKEN}

.PHONY: create-kustomization
create-kustomization: create-source
	flux create kustomization kind --source=k8s-gitops-flux-cluster --path="./clusters/kind" --prune=true --interval=24h

create-namespace: create-cluster
	@if ! kubectl get namespaces kind --output name; then \
	 	kubectl create namespace kind;\
	fi

create-docker-credentials: check-env create-namespace
	@if ! kubectl get secrets --namespace kind kind-docker-registry --output name; then \
		kubectl create secret docker-registry kind-docker-registry --namespace=kind --docker-server=ghcr.io --docker-username=${GITHUB_USER} --docker-password=${GITHUB_TOKEN};\
	fi

create-generic-credentials: check-env create-namespace
	@if ! kubectl get secrets --namespace kind kind-generic --output name; then \
		kubectl create secret generic kind-generic --namespace=kind --from-literal=username=$SEA_USER --from-literal=password=$SEA_PASSWORD;\
	fi

.PHONY: reconcile-cluster
reconcile-cluster:
	flux reconcile source git k8s-gitops-flux-cluster

.PHONY: get-nodes
get-nodes: create-cluster
	kubectl get nodes

.PHONY: delete-cluster
delete-cluster:
	kind delete cluster
