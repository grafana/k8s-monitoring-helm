all: k8s-monitoring-application.yaml

# Declare the target as phony to ensure it always runs
.PHONY: k8s-monitoring-application.yaml
k8s-monitoring-application.yaml:
	@if [ -n "$$BRANCH_NAME" ]; then \
  		echo "Setting targetRevision to $$BRANCH_NAME"; \
		yq eval '.spec.source.targetRevision = strenv(BRANCH_NAME)' k8s-monitoring-application.yaml > temp.yaml; \
		cp temp.yaml k8s-monitoring-application.yaml; \
		rm temp.yaml; \
	fi
