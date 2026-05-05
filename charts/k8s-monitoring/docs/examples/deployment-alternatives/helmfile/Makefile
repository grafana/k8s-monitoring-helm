SHELL := /bin/bash

.rendered/output.yaml: helmfile.yaml
	helm template k8smon ../../../.. -f <(yq '.releases[0].values[0]' $<) > $@

.PHONY: all
all: .rendered/output.yaml
