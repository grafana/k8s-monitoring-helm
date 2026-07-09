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

TARGET_REVISION ?= $(shell git rev-parse --abbrev-ref HEAD)
export TARGET_REVISION

# Declare the target as phony to ensure it always runs
.PHONY: ../k8s-monitoring-application.yaml
../k8s-monitoring-application.yaml:
	@echo "Setting targetRevision to $${TARGET_REVISION}"
	@yq eval '.spec.source.targetRevision = strenv(TARGET_REVISION)' $@ > temp.yaml
	@cp temp.yaml $@
	@rm temp.yaml

values.yaml: ../k8s-monitoring-application.yaml
	yq eval '.spec.source.helm.valuesObject' $< > $@

output.yaml: values.yaml
	$(HELM) template k8smon ../../../../.. -f $< > $@
