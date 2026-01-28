FROM grafana/pyroscope:1.18.0@sha256:e7edae4fd99dbb8695a1e03d7db96ab247630cf83842407908922b2f66aafc6a AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
