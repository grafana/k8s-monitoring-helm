FROM quay.io/curl/curl:latest@sha256:f6710cb71617689b9e3522bde531a1a59f3d39e848be4cb450c9f87c5d15c3a5 AS profilecli-downloader
ARG PROFILECLI_VERSION=1.15.0
ARG TARGETARCH

# Download profilecli for Pyroscope queries
RUN curl -fL https://github.com/grafana/pyroscope/releases/download/v${PROFILECLI_VERSION}/profilecli_${PROFILECLI_VERSION}_linux_${TARGETARCH}.tar.gz | tar xvz && \
    chmod +x profilecli

FROM nixery.dev/shell/bc/curl/jq/file@sha256:63303658c01a4a67648d3320cb47b0607ff762c9f039b1fa2c7e3c9dc66274e5 AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file@sha256:7550dfd3532d8d020af531a11b2c6bf0141830259483a191499dcbec04879e81 AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=profilecli-downloader /home/curl_user/profilecli /usr/local/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
