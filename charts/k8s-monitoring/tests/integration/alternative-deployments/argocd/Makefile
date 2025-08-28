clean: ;

all: k8s-monitoring-application.yaml

BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD)

# Declare the target as phony to ensure it always runs
.PHONY: k8s-monitoring-application.yaml
k8s-monitoring-application.yaml:
	@echo "Setting targetRevision to $(BRANCH_NAME)"
	@yq eval '.spec.source.targetRevision = "$(BRANCH_NAME)"' k8s-monitoring-application.yaml > temp.yaml
	@cp temp.yaml k8s-monitoring-application.yaml
	@rm temp.yaml
