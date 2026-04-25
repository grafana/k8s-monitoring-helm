FROM grafana/pyroscope:1.18.1@sha256:0ad897bb457228c7d1133ce7004f83052e635be9daf4a7cc90364317637e9754 AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file@sha256:20346eb21a625aff3db70398efa548e49ed96675ecc20d2c5ebb90849a9680da AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file@sha256:c7d60d02119214e284dbd74698abff532e115a09208db21e7030fb944bab9bb7 AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
