FLUX_COMPONENTS?=source-controller,kustomize-controller,helm-controller

all: check-env cluster flux-system flux-cluster

.PHONY: check-env
check-env:
ifndef GITHUB_USER
	$(error GITHUB_USER is undefined)
endif
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN is undefined)
endif

.PHONY: cluster
cluster:
	@if ! kind get clusters | grep -q kind; then \
		kind create cluster --config e2e/kind.yaml;\
	fi

.PHONY: flux-system
flux-system: cluster
	flux install --namespace flux-system --components $(FLUX_COMPONENTS)

.PHONY: flux-cluster-namespace
flux-cluster-namespace: cluster
	@if ! kubectl get namespaces flux-cluster --output name; then \
	 	kubectl create namespace flux-cluster;\
	fi

.PHONY: github-credentials
github-credentials: check-env flux-system flux-cluster-namespace
	@echo flux create secret git github-credentials --namespace flux-cluster --url=https://github.com/ --username=$(GITHUB_USER) --password=***
	@flux create secret git github-credentials --namespace flux-cluster --url=https://github.com/ --username=$(GITHUB_USER) --password=$(GITHUB_TOKEN)

.PHONY: flux-cluster
flux-cluster: check-env github-credentials
	kustomize build kind | kubectl apply --overwrite=false -f -

kind-namespace: cluster
	@if ! kubectl get namespaces kind --output name; then \
	 	kubectl create namespace kind;\
	fi

create-docker-credentials: check-env kind-namespace
	@if ! kubectl get secrets --namespace kind kind-docker-registry --output name; then \
		kubectl create secret docker-registry kind-docker-registry --namespace=kind --docker-server=ghcr.io --docker-username=${GITHUB_USER} --docker-password=${GITHUB_TOKEN};\
	fi

create-generic-credentials: check-env kind-namespace
	@if ! kubectl get secrets --namespace kind kind-generic --output name; then \
		kubectl create secret generic kind-generic --namespace=kind --from-literal=username=$SEA_USER --from-literal=password=$SEA_PASSWORD;\
	fi

.PHONY: reconcile
reconcile:
	flux reconcile source git flux-cluster --namespace=flux-cluster

.PHONY: clean
clean:
	kind delete cluster
