FROM grafana/pyroscope:2.0.1@sha256:704889ae04768d982a0a71935bb054948993ddc3fe80234611d20877ba8be4c9 AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
