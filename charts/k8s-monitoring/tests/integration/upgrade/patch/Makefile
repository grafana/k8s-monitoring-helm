.PHONY: check
check:
	if yq eval '.version' ../../../../Chart.yaml | grep -q "[[:digit:]]\+\.[[:digit:]]\+\.0"; then \
		echo "Patch version is 0."; \
		exit 2; \
	fi

.PHONY: clean
clean: ;

.PHONY: all
all: ;

.PHONY: run-test
run-test:
	../../../../../../scripts/run-cluster-test.sh .
