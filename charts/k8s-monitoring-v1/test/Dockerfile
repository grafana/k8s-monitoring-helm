FROM grafana/pyroscope:1.18.1@sha256:0ad897bb457228c7d1133ce7004f83052e635be9daf4a7cc90364317637e9754 AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file@sha256:4d77c6770c09dc9dea78660df36454bcf8a058fe84f48ec1f759a48aa805b6c7 AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file@sha256:7916dd90a127ee326da88bffadddc8a327b96687c7703b466d50ca7016b58379 AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
