clean: ;
all:
	# Set the KUBECONFIG in helmfile.yaml
	# This is a workaround for https://github.com/helmfile/helmfile/issues/2167
	yq eval ".helmDefaults.diffArgs[2]=\"--kubeconfig=$(KUBECONFIG)\"" helmfile.yaml > helmfile.yaml.temp
	mv helmfile.yaml.temp helmfile.yaml
