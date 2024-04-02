FROM nixery.dev/shell/bc/curl/jq

# Download profilecli for Pyroscope queries
RUN curl -fL https://github.com/grafana/pyroscope/releases/download/v1.5.0/profilecli_1.5.0_linux_amd64.tar.gz | tar xvz && \
    chmod +x profilecli && \
    mv profilecli /usr/local/bin

COPY ["config-analysis.sh", "query-test.sh", "/etc/bin/"]
