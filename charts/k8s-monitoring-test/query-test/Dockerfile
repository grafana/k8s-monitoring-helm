FROM grafana/pyroscope:1.10.0 AS pyroscope
FROM ubuntu

RUN apt-get update && apt-get install -y bc curl gettext jq && rm -rf /var/lib/apt/lists/*
COPY --from=pyroscope /usr/bin/profilecli /usr/bin/profilecli

COPY ["query-test.sh", "/usr/bin/"]
