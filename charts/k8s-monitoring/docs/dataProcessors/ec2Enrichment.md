# EC2 Enrichment Processor

The EC2 enrichment processor copies AWS EC2 instance tags onto telemetry data as it flows from features to
destinations. It uses the [discovery.ec2](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.ec2/)
Alloy component to discover the EC2 instances in a region and their tags (exposed as `__meta_ec2_tag_<tag name>`
labels), then attaches the requested tags to telemetry. It supports the label-based ecosystems: Prometheus metrics,
Loki logs, and Pyroscope profiles.

Telemetry is matched to its source instance by its `node` label, which is compared against the instance's private DNS
name (`__meta_ec2_private_dns_name`). On Amazon EKS, the Kubernetes node name defaults to the instance's private DNS
name, so node-labeled telemetry matches its backing EC2 instance.

The `tags` setting is a map of `<telemetry label>: <EC2 tag name>`: the key is the label added to the telemetry data,
and the value is the name of the EC2 instance tag to copy. For example, `tags: {team: Team}` copies the instance's
`Team` tag to the `team` label.

This data processor is considered experimental and subject to change.

<!-- textlint-disable terminology -->
## Values

### General

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| refreshInterval | string | 60s | How often to refresh the list of discovered EC2 instances and their tags. |
| region | string | `""` | The AWS region to discover EC2 instances in. If not set, the region is determined from the EC2 instance metadata of the host running the collector. |
| roleARN | string | `""` | The ARN of the role to assume when discovering EC2 instances. If not set, the default credentials from the AWS credential chain are used. |
| tags | object | `{}` | EC2 instance tags to copy to telemetry data, as a map of `<telemetry label>: <EC2 tag name>`. Applies to data carrying a `node` label that matches an instance's private DNS name. |
<!-- textlint-enable terminology -->

## Requirements

-   This processor uses the experimental Alloy components
    ([prometheus.enrich](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.enrich/),
    [loki.enrich](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.enrich/), and
    [pyroscope.enrich](https://grafana.com/docs/alloy/latest/reference/components/pyroscope/pyroscope.enrich/)), so any
    collector running it must set `alloy.stabilityLevel: experimental`. The chart validates this at install time.
-   The telemetry label name is sanitized to a valid label name: dashes, dots, and slashes become underscores (for
    example, the telemetry label `cost-center` becomes `cost_center`).
-   Enrichment requires the telemetry to carry a `node` label whose value matches an instance's private DNS name. Most
    Kubernetes metrics, logs, and profiles already carry a `node` label; telemetry without one is passed through
    unchanged.
-   AWS credentials are sourced from the standard AWS credential chain (IRSA, instance profile, or environment
    variables). The instance or role used must have the `ec2:DescribeInstances` and `ec2:DescribeAvailabilityZones`
    permissions. Use `roleARN` to assume a specific role (for example, for cross-account discovery).
-   Enrichment polls the EC2 API for instances and tags. To keep that cost down, the discovery is rendered once per
    collector and shared by all of the processor's pipelines on that collector.

## Example

This example defines an `ec2-tags` processor that copies the `Team` and `Environment` EC2 instance tags onto cluster
metrics and pod logs:

```yaml
dataProcessors:
  ec2-tags:
    type: ec2Enrichment
    region: us-east-1
    tags:
      team: Team
      environment: Environment

clusterMetrics:
  enabled: true
  dataProcessors: [ec2-tags]

podLogsViaLoki:
  enabled: true
  dataProcessors: [ec2-tags]

collectors:
  alloy-metrics:
    alloy:
      stabilityLevel: experimental
  alloy-logs:
    alloy:
      stabilityLevel: experimental
```

Metrics and logs that carry a `node` label gain `team` and `environment` labels with the values from the matching EC2
instance's tags.
