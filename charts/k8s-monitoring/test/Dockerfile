FROM quay.io/curl/curl:latest AS profilecli-downloader
# Download profilecli for Pyroscope queries
RUN curl -fL https://github.com/grafana/pyroscope/releases/download/v1.5.0/profilecli_1.5.0_linux_amd64.tar.gz | tar xvz && \
    chmod +x profilecli

FROM nixery.dev/shell/bc/curl/jq

COPY --from=profilecli-downloader /home/curl_user/profilecli /usr/local/bin/profilecli
COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
