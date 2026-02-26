FROM grafana/pyroscope:1.18.1@sha256:0ad897bb457228c7d1133ce7004f83052e635be9daf4a7cc90364317637e9754 AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file@sha256:c688f75b13b29635bc1db1c1f33f8d655d53b8db0e1d6e411bcd48361af28d89 AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file@sha256:21ad1bb7c1234f7a8f2bc16597a661d986acc38382998ed23b75f352b8d31eb1 AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
