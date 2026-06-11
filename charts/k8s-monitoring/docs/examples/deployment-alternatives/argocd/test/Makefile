HELM_VERSION ?=
ifeq ($(HELM_VERSION),)
HELM = helm
else
HELM = ../../../../../../scripts/helm-with-version $(HELM_VERSION)
endif

.PHONY: clean
clean: ;

.PHONY: all
all: ../k8s-monitoring-application.yaml

BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD)
HEAD_REPOSITORY ?= $(shell if [ -n "$$GITHUB_EVENT_PATH" ] && [ -f "$$GITHUB_EVENT_PATH" ]; then jq -r '.pull_request.head.repo.full_name // empty' "$$GITHUB_EVENT_PATH"; fi)
REPO_URL ?= $(if $(HEAD_REPOSITORY),https://github.com/$(HEAD_REPOSITORY).git,https://github.com/grafana/k8s-monitoring-helm.git)

# Declare the target as phony to ensure it always runs
.PHONY: ../k8s-monitoring-application.yaml
../k8s-monitoring-application.yaml:
	@echo "Setting targetRevision to $(BRANCH_NAME)"
	@echo "Setting repoURL to $(REPO_URL)"
	@yq eval '.spec.source.targetRevision = "$(BRANCH_NAME)" | .spec.source.repoURL = "$(REPO_URL)"' $@ > temp.yaml
	@cp temp.yaml $@
	@rm temp.yaml

values.yaml: ../k8s-monitoring-application.yaml
	yq eval '.spec.source.helm.valuesObject' $< > $@

output.yaml: values.yaml
	$(HELM) template k8smon ../../../../.. -f $< > $@
