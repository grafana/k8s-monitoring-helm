<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# EC2 Enrichment data processor

This example uses the `ec2Enrichment` data processor to copy AWS EC2 instance tags onto telemetry data. Each entry
maps `<telemetry label>: <EC2 tag name>`. A single `ec2-tags` processor copies:

| Source       | Tag    | Resulting label / attribute |
| ------------ | ------ | --------------------------- |
| EC2 instance | `Team` | `team`                      |

The processor uses `discovery.ec2` to list instances in the `ap-northeast-2` region once per collector, then a shared
`discovery.relabel` maps the `__meta_ec2_tag_Team` meta label to `team`.

The processor matches telemetry to its source instance by comparing each series' `node` label against the instance's
`__meta_ec2_private_dns_name`, so it can enrich any feature whose telemetry carries a `node` label. Today it supports
these label-based ecosystems:

| Telemetry | Ecosystem   | Enrich component               |
| --------- | ----------- | ------------------------------ |
| Metrics   | `prometheus` | `prometheus.enrich`           |
| Logs      | `loki`       | `loki.enrich`                 |
| Profiles  | `pyroscope`  | `pyroscope.enrich`            |

Everything runs on a single `alloy` collector, which shows the processor's shared instance discovery: every enrich
stage reads targets from one `discovery.ec2`/`discovery.relabel` pair, so the EC2 API is only queried once per
collector.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: ec2-enrichment-example-cluster

destinations:
  localPrometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
    auth:
      type: basic
      username: promuser
      password: prometheuspassword

  localLoki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword

dataProcessors:
  # Copies the EC2 instance `Team` tag onto telemetry, matching each node's `node` label to
  # its instance private DNS name via discovery.ec2.
  ec2-tags:
    type: ec2Enrichment
    region: ap-northeast-2
    tags:
      team: Team

hostMetrics:
  enabled: true
  dataProcessors: [ec2-tags]
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true

nodeLogs:
  enabled: true
  dataProcessors: [ec2-tags]

podLogsViaLoki:
  enabled: true

collectors:
  alloy:
    presets: [clustered, filesystem-log-reader, daemonset]
    alloy:
      stabilityLevel: experimental  # Required for prometheus.enrich (ec2Enrichment processor)

telemetryServices:
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
