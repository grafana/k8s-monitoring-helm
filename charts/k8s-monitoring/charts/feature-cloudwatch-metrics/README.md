<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: CloudWatch Metrics

The CloudWatch Metrics feature gathers metrics from [AWS CloudWatch](https://aws.amazon.com/cloudwatch/) and delivers
them to your metrics destinations alongside the rest of your Kubernetes telemetry.

## Usage

```yaml
cloudwatchMetrics:
  enabled: true
  instances:
    - name: production
      regions: [eu-central-1]
      discoveryJobs:
        - type: AWS/SQS
          searchTags:
            scrape: "true"
          metrics:
            - name: NumberOfMessagesSent
              statistics: [Sum]
```

Each entry in `instances` becomes its own exporter, so use separate instances to query different STS regions or to keep
AWS accounts apart. See the [instance settings](./docs/instance.md) for everything available on an entry.

## How it works

For every instance, this feature generates a
[`prometheus.exporter.cloudwatch`](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.cloudwatch/)
component, a `prometheus.scrape` that gathers from it, and a `prometheus.relabel` that sets the `instance` and `job`
labels and applies any metric tuning.

The exporter queries the CloudWatch API rather than scraping anything in your cluster, so the collector it runs on needs
no access to the monitored resources — only AWS credentials.

### Authentication

The exporter uses the credentials available to the collector Pod, which is the normal setup with
[IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) or
[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html). The role needs
`cloudwatch:GetMetricData`, `cloudwatch:ListMetrics`, `tag:GetResources`, and the list or describe calls for the
services being gathered.

To gather from other accounts, set `roles` on an instance or on a single job to assume a role per account.

### Cost

Every CloudWatch API call the exporter makes is billed by AWS, so this feature defaults to the `alloy-singleton`
collector: the exporter runs in every replica of its collector, and each replica would be billed for its own calls.

The generated scrapes enable clustering so that a multi-replica collector shards the exporter targets rather than every
replica gathering all of them. The chart will not render a configuration that would silently double your CloudWatch
bill — it fails with instructions instead.

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `testing.enabled` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

<!-- textlint-disable terminology -->
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
| TylerHelmuth | <tyler.helmuth@grafana.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cloudwatch-metrics>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.namespaceOverride | string | `""` | Override the namespace for namespaced resources created by this chart. |
| global.scrapeClassicHistograms | bool | `false` | Whether to scrape a classic histogram that’s also exposed as a native histogram. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |
| global.scrapeNativeHistograms | bool | `false` | Whether to scrape native histograms. |
| global.scrapeProtocols | list | `["OpenMetricsText1.0.0","OpenMetricsText0.0.1","PrometheusText0.0.4"]` | The protocols to negotiate during a Prometheus metrics scrape, in order of preference. |
| global.scrapeTimeout | string | `"10s"` | The timeout for scraping metrics. |

### Instances

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| instances | list | `[]` | One entry per CloudWatch exporter to run. Each instance becomes its own [prometheus.exporter.cloudwatch](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.cloudwatch/) component with its own scrape and metric processing, so use separate instances to query different STS regions or to keep AWS accounts apart. See the [instance settings](./docs/instance.md) for the options available on each entry. |
