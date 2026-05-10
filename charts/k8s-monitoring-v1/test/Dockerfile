FROM grafana/pyroscope:1.21.1@sha256:23f366803b418ca6b80f510f2dbcec22178a836dfe1fe828261d93273c0a4f97 AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
