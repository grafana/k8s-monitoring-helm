FROM grafana/pyroscope:1.18.1@sha256:0ad897bb457228c7d1133ce7004f83052e635be9daf4a7cc90364317637e9754 AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file@sha256:672c38e3050b7bac6a85b563b200523687b3a2bb23a8b7c622f714186d3c7ebd AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file@sha256:0f5e397ee1ea621cc0716075d2f73376ab625178efb58b49844cdd8fb924ff3b AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
