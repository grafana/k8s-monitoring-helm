FROM quay.io/curl/curl:latest AS profilecli-downloader
ARG PROFILECLI_VERSION=1.5.0
ARG TARGETARCH

# Download profilecli for Pyroscope queries
RUN curl -fL https://github.com/grafana/pyroscope/releases/download/v${PROFILECLI_VERSION}/profilecli_${PROFILECLI_VERSION}_linux_${TARGETARCH}.tar.gz | tar xvz && \
    chmod +x profilecli

FROM nixery.dev/shell/bc/curl/jq/file AS base-image-amd64
FROM nixery.dev/arm64/shell/bc/curl/jq/file AS base-image-arm64

FROM base-image-${TARGETARCH} AS final
COPY --from=profilecli-downloader /home/curl_user/profilecli /usr/local/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
