README.md: README.md.gotmpl
	docker run --rm --volume "$$(pwd):/helm-docs" -u $$(id -u) jnorwood/helm-docs:latest

values.schema.json: values.yaml values.schema.modifications.json
	docker run --rm --platform linux/amd64 -v "$$(pwd):/chart" --entrypoint sh alpine/helm \
		--command -c 'helm plugin install https://github.com/karuppiah7890/helm-schema-gen.git && \
			helm schema-gen /chart/values.yaml > /chart/values.schema.generated.json'
	jq -s '.[0] * .[1] \
		| del(.properties.opencost.properties.opencost) \
		| del(.properties["kube-state-metrics"].properties.nodeSelector) \
		| del(.properties["prometheus-node-exporter"].properties.nodeSelector) \
		| del(.properties["prometheus-windows-exporter"].properties.config) \
		| del(.properties["grafana-agent"]) \
		| del(.properties["grafana-agent-logs"]) \
		' values.schema.generated.json values.schema.modifications.json > values.schema.json
	rm values.schema.generated.json
