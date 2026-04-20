SHELL := /bin/bash

.rendered/output.yaml: helmfile.yaml
	helm template k8smon ../../../.. -f <(yq '.releases[0].values[0]' $<) | sed 's|value: "AIzaSyD29bGxmHAVEOBYtgd8sYM2gM2ekfxQX4U"|&  # trufflehog:ignore|' > $@

.PHONY: all
all: .rendered/output.yaml
