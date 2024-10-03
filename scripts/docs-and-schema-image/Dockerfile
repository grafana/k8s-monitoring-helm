FROM jnorwood/helm-docs:v1.14.2 AS helm-docs

FROM alpine/helm:3.15.4
RUN apk add --no-cache jq

COPY --from=helm-docs /usr/bin/helm-docs /usr/bin/helm-docs
COPY create-docs-and-schema.sh /usr/bin/create-docs-and-schema.sh

RUN helm plugin install https://github.com/karuppiah7890/helm-schema-gen.git

ENTRYPOINT ["/usr/bin/create-docs-and-schema.sh"]
