# CloudWatch Exporter Instance Settings

These are the settings available on each entry in `cloudwatchMetrics.instances`. Every instance becomes its own
[`prometheus.exporter.cloudwatch`](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.cloudwatch/)
component, with its own scrape and metric processing.

## Jobs

An instance gathers nothing until it has at least one job. There are three kinds, and an instance can mix them:

*   `discoveryJobs` finds resources by tag and gathers the listed metrics for each one. This is the usual choice for a
    whole AWS service.
*   `staticJobs` gathers metrics for an explicit set of dimensions, without discovery. Use it when the resource has no
    tags to search on.
*   `customNamespaceJobs` gathers metrics from a namespace that CloudWatch discovery does not cover, such as one your
    own application publishes.

Every job needs at least one `metrics` entry, and each metric needs a `name` and `statistics`:

```yaml
metrics:
  - name: CPUUtilization
    statistics: [Average, Maximum]
```

A metric may also set `period`, `length`, `nilToZero`, and `addCloudwatchTimestamp`. When it does not, those fall back
to the value set on the job, which is usually what you want.

Jobs inherit the instance's `regions` and `roles` unless they set their own.

## Regions

`regions` lists the AWS regions to query. `stsRegion` is the region used to call STS for account information, and
defaults to the first entry in `regions`. Set it explicitly if every job sets its own regions.

## Authentication

By default no `role` is configured, so the exporter uses whatever credentials Alloy already has. That is the normal
setup with [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) or
[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html).

Set `roles` to assume one or more IAM roles instead. Listing more than one role gathers the same jobs once per role,
which is how a single instance covers several AWS accounts:

```yaml
roles:
  - roleArn: arn:aws:iam::111111111111:role/CloudWatchReadOnly
  - roleArn: arn:aws:iam::222222222222:role/CloudWatchReadOnly
    externalId: shared-secret
```

## Cost

Every CloudWatch API call the exporter makes is billed by AWS. Two settings have a direct effect on that bill:

*   `metrics.scrapeInterval` — with decoupled scraping disabled, every scrape triggers CloudWatch API calls.
*   `decoupledScraping` — gathers metrics on a background timer instead, so the API call rate no longer follows the
    scrape interval. Note that the background poller runs in every replica of the collector and is not sharded by
    clustering, so keep this on a single-replica collector.

## Values

### Jobs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| customNamespaceJobs | list | `[]` | Jobs that gather metrics from a custom (non-AWS) CloudWatch namespace, discovering dimensions automatically. Each entry supports: `name` (required, becomes the `name` label on the metrics), `namespace` (required), `metrics` (required, see below), `regions`, `roles`, `customTags`, `dimensionNameRequirements`, `period`, `length`, `delay`, `nilToZero`, `recentlyActiveOnly`, and `addCloudwatchTimestamp`. The `name` is used as an Alloy block label, so it may only contain letters, digits, and underscores. |
| discoveryJobs | list | `[]` | Jobs that discover resources by tag and gather the listed metrics for each one. This is the usual way to gather metrics for a whole AWS service. Each entry supports: `type` (required, a CloudWatch service alias like `AWS/EC2` or `sqs`), `metrics` (required, see below), `regions`, `roles`, `searchTags`, `customTags`, `dimensionNameRequirements`, `period`, `length`, `delay`, `nilToZero`, `recentlyActiveOnly`, and `addCloudwatchTimestamp`. |
| staticJobs | list | `[]` | Jobs that gather metrics for an explicit set of dimensions, without discovery. Use these when the resource has no tags to search on, or for namespaces that CloudWatch discovery does not support. Each entry supports: `name` (required, becomes the `name` label on the metrics), `namespace` (required), `dimensions` (required), `metrics` (required, see below), `regions`, `roles`, `customTags`, `period`, `length`, `delay`, and `nilToZero`. The `name` is used as an Alloy block label, so it may only contain letters, digits, and underscores. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| decoupledScraping.enabled | bool | `false` | Whether to gather CloudWatch metrics asynchronously. Note: the background poller runs in every replica of the assigned collector, so each replica makes its own CloudWatch API calls. Keep this feature on a single-replica collector to avoid multiplying API costs. |
| decoupledScraping.scrapeInterval | string | `"5m"` | How frequently to gather CloudWatch metrics in the background. |
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from the CloudWatch exporter. When `decoupledScraping` is disabled, every scrape triggers CloudWatch API calls, so a short interval here directly increases AWS costs. Overrides `global.scrapeInterval`. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from the CloudWatch exporter. CloudWatch queries can be slow, so this may need to be higher than for a typical exporter. Overrides `global.scrapeTimeout`. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| discoveryExportedTags | object | `{}` | Tags to export as labels on all metrics of a given service. Format: `<namespace>: [<tag>, ...]`. For example, `{"AWS/EC2": ["Owner", "Environment"]}`. |
| fipsDisabled | bool | `true` | Disable the use of FIPS compatible endpoints. Set this to `false` only when running in a region that requires FIPS endpoints. |
| jobLabel | string | `"integrations/cloudwatch"` | The value of the job label for metrics scraped from this instance. |
| labelsSnakeCase | bool | `false` | Output metric labels in snake case instead of camel case. |
| name | string | `""` | Name for this CloudWatch exporter instance. Used as the `instance` label on the scraped metrics and to name the generated Alloy components, so it must be unique within the feature. |
| regions | list | `[]` | Default AWS regions to query. Used by any job in this instance that does not set its own `regions`. |
| stsRegion | string | The first entry in `regions` | The AWS region used when calling STS to retrieve account information. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for this instance. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target. |
| metrics.maxCacheSize | int | `100000` | Sets the max_cache_size for the prometheus.relabel component for this instance. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)). Overrides `global.maxCacheSize`. |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Authentication

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| roles | list | `[]` | IAM roles to assume, used by any job in this instance that does not set its own `roles`. Leave empty to use the credentials Alloy already has, which is the normal setup when using IRSA or EKS Pod Identity. Listing more than one role scrapes the same jobs once per role, which is how you gather metrics from several AWS accounts. Each entry takes a `roleArn` and an optional `externalId`. |
