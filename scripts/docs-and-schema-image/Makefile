.PHONY: build
build: Dockerfile create-docs-and-schema.sh
	docker build --platform linux/amd64 -t ghcr.io/grafana/helm-docs-and-schema-gen .

.PHONY: push
push: build
	docker push ghcr.io/grafana/helm-docs-and-schema-gen
