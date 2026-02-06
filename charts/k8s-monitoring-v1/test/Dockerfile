FROM grafana/pyroscope:1.18.0@sha256:e7edae4fd99dbb8695a1e03d7db96ab247630cf83842407908922b2f66aafc6a AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file@sha256:c688f75b13b29635bc1db1c1f33f8d655d53b8db0e1d6e411bcd48361af28d89 AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file@sha256:21ad1bb7c1234f7a8f2bc16597a661d986acc38382998ed23b75f352b8d31eb1 AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
