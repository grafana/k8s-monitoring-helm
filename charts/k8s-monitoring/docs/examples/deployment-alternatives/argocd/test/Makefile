.PHONY: clean
clean: ;

.PHONY: all
all: ../k8s-monitoring-application.yaml

BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD)

# Declare the target as phony to ensure it always runs
.PHONY: ../k8s-monitoring-application.yaml
../k8s-monitoring-application.yaml:
	@echo "Setting targetRevision to $(BRANCH_NAME)"
	@yq eval '.spec.source.targetRevision = "$(BRANCH_NAME)"' $@ > temp.yaml
	@cp temp.yaml $@
	@rm temp.yaml

values.yaml: ../k8s-monitoring-application.yaml
	yq eval '.spec.source.helm.valuesObject' $< > $@

output.yaml: values.yaml
	helm template k8smon ../../../../.. -f $< > $@
