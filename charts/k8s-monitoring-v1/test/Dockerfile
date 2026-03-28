FROM grafana/pyroscope:1.19.1@sha256:d5d38187f7593fdf5643ba29e67099206e8d4dee6207f78d028ea3fe621cc04d AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
