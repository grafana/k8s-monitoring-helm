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
| schwatvogel | <572536+schwatvogel@users.noreply.github.com> |  |
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

### Instance Settings

These are the settings for each entry in `instances`. See the [instance settings](./docs/instance.md) for how the jobs,
regions, and authentication settings fit together, and for the options on each job and metric.

#### Jobs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| customNamespaceJobs | list | `[]` | Jobs that gather metrics from a custom (non-AWS) CloudWatch namespace, discovering dimensions automatically. Each entry supports: `name` (required, becomes the `name` label on the metrics), `namespace` (required), `metrics` (required, see below), `regions`, `roles`, `customTags`, `dimensionNameRequirements`, `period`, `length`, `delay`, `nilToZero`, `recentlyActiveOnly`, and `addCloudwatchTimestamp`. The `name` is used as an Alloy block label, so it may only contain letters, digits, and underscores. |
| discoveryJobs | list | `[]` | Jobs that discover resources by tag and gather the listed metrics for each one. This is the usual way to gather metrics for a whole AWS service. Each entry supports: `type` (required, a CloudWatch service alias like `AWS/EC2` or `sqs`), `metrics` (required, see below), `regions`, `roles`, `searchTags`, `customTags`, `dimensionNameRequirements`, `period`, `length`, `delay`, `nilToZero`, `recentlyActiveOnly`, and `addCloudwatchTimestamp`. |
| staticJobs | list | `[]` | Jobs that gather metrics for an explicit set of dimensions, without discovery. Use these when the resource has no tags to search on, or for namespaces that CloudWatch discovery does not support. Each entry supports: `name` (required, becomes the `name` label on the metrics), `namespace` (required), `dimensions` (required), `metrics` (required, see below), `regions`, `roles`, `customTags`, `period`, `length`, `delay`, and `nilToZero`. The `name` is used as an Alloy block label, so it may only contain letters, digits, and underscores. |

#### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| decoupledScraping.enabled | bool | `false` | Whether to gather CloudWatch metrics asynchronously. Note: the background poller runs in every replica of the assigned collector, so each replica makes its own CloudWatch API calls. Keep this feature on a single-replica collector to avoid multiplying API costs. |
| decoupledScraping.scrapeInterval | string | `"5m"` | How frequently to gather CloudWatch metrics in the background. |
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from the CloudWatch exporter. When `decoupledScraping` is disabled, every scrape triggers CloudWatch API calls, so a short interval here directly increases AWS costs. Overrides `global.scrapeInterval`. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from the CloudWatch exporter. CloudWatch queries can be slow, so this may need to be higher than for a typical exporter. Overrides `global.scrapeTimeout`. |

#### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| discoveryExportedTags | object | `{}` | Tags to export as labels on all metrics of a given service. Format: `<namespace>: [<tag>, ...]`. For example, `{"AWS/EC2": ["Owner", "Environment"]}`. |
| fipsDisabled | bool | `true` | Disable the use of FIPS compatible endpoints. Set this to `false` only when running in a region that requires FIPS endpoints. |
| jobLabel | string | `"integrations/cloudwatch"` | The value of the job label for metrics scraped from this instance. |
| labelsSnakeCase | bool | `false` | Output metric labels in snake case instead of camel case. |
| name | string | `""` | Name for this CloudWatch exporter instance. Used as the `instance` label on the scraped metrics and to name the generated Alloy components, so it must be unique within the feature. |
| regions | list | `[]` | Default AWS regions to query. Used by any job in this instance that does not set its own `regions`. |
| stsRegion | string | The first entry in `regions` | The AWS region used when calling STS to retrieve account information. |

#### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for this instance. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target. |
| metrics.maxCacheSize | int | `100000` | Sets the max_cache_size for the prometheus.relabel component for this instance. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)). Overrides `global.maxCacheSize`. |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

#### Authentication

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| roles | list | `[]` | IAM roles to assume, used by any job in this instance that does not set its own `roles`. Leave empty to use the credentials Alloy already has, which is the normal setup when using IRSA or EKS Pod Identity. Listing more than one role scrapes the same jobs once per role, which is how you gather metrics from several AWS accounts. Each entry takes a `roleArn` and an optional `externalId`. |
