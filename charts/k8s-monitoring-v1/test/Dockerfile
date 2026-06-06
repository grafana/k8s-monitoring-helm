FROM grafana/pyroscope:2.0.3@sha256:cfd00e7f73c2a5fe5e8a51d4790065e2343f5a20e41293c4fa3b9b03a91e3a40 AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
