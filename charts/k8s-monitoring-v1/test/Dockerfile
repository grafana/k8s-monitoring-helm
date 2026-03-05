FROM grafana/pyroscope:1.18.1@sha256:0ad897bb457228c7d1133ce7004f83052e635be9daf4a7cc90364317637e9754 AS pyroscope
FROM nixery.dev/shell/bc/curl/jq/file@sha256:cb7016bd03431e3195d4895fe7899eb85da3ebce85cceaef05d4048b25509338 AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file@sha256:4c206f928540dc4e5ee2b22f6e7a5085313bf0af4f5d26151566adf60d8cb7c6 AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
