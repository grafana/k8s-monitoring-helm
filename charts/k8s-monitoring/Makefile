values.schema.json: values.yaml values.schema.modifications.json
	docker run -it --rm --platform linux/amd64 -v "$(shell pwd):/chart" --entrypoint sh alpine/helm \
		--command -c 'helm plugin install https://github.com/karuppiah7890/helm-schema-gen.git && \
			helm schema-gen /chart/values.yaml > /chart/values.schema.generated.json'
	jq --indent 4 -s '.[0] * .[1] \
		| del(.properties["grafana-agent"]) \
		| del(.properties["grafana-agent-logs"]) \
		| del(.properties["kube-state-metrics"].properties.nodeSelector) \
		| del(.properties["prometheus-node-exporter"].properties.nodeSelector) \
		| del(.properties["prometheus-windows-exporter"].properties.config) \
		| del(.properties.opencost.properties.opencost) \
' values.schema.generated.json values.schema.modifications.json > values.schema.json
	rm values.schema.generated.json

HAS_HELM_DOCS := $(shell command -v helm-docs;)


README.md: README.md.gotmpl values.yaml
ifdef HAS_HELM_DOCS
	helm-docs
else
	docker run --rm --volume "$(shell pwd):/helm-docs" -u $(shell id -u) jnorwood/helm-docs:latest
endif
