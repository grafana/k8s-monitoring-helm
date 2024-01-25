# Customizing the Configuration

While this chart provides a capable configuration for Kubernetes Cluster infrastructure monitoring, you can use this document to customize your configuration and understand how these customizations affect it.

## Overview

Each telemetry data source (e.g. metrics, logs, events, traces) typically goes through the same process:

1. Discovery - How does the collector find the data source?
2. Scraping - How should the data get gathered?
3. Processing - What work needs to be done to the data?
4. Delivery - Where should the data be sent for storage?

## Metrics

Metrics are typically gathered using Prometheus-style scraping.

### Discovery customizations

These fields affect how metric targets are discovered. Typically, you'll make changes to these values if the Grafana Agent is not detecting the target.

* `metrics.<source>.extraRelabelingRules` - These rules are used to populate the rules section of a
  [discovery.relabel](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/) component. They filter from all Nodes, services, endpoints, or Pods on the
Cluster to a specific one that has the metrics. 
  Use these rules to target a specific service.
* `metrics.extraRelabelingRules` - Same as above, but these rules are applied to all metric sources.
* `metrics.<source>.labelMatchers` - Defines what Kubernetes labels need to match on the target.
* `metrics.<source>.service.port` - This section defines the name of the port that has the metrics endpoint. 

### Scraping customizations

These fields affect how metric targets are scraped. Typically, you'll make changes here if 
you want to change something about how often to scrape or which target to scrape.

* `metrics.<source>.scrapeInterval` - How often to scrape metrics from a target.
* `metrics.scrapeInterval` - Same as above, but changes the global default.
* `metrics.<source>.service.isTLS` - Determines whether the Agent use HTTPS and TLS to scrape the target instead of HTTP.

### Processing customizations

These fields allow for customizations of the metrics after they have been scraped, but before being sent to the external
metric service for storage. By default, we already use an "allow list" to filter down to a specific set of metrics,
which drops metrics that are not useful for monitoring Kubernetes clusters. Other typical changes that you might want to
do here include setting, modifying, or dropping metric labels.

* `metrics.<source>.extraMetricsRelabelingRules` - These rules are used to modify metrics and will populate the rules
  section of a [prometheus.relabel](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/)
  component. Use these rules to do arbitrary modifications to metrics or metric labels.
* `metrics.extraMetricsRelabelingRules` - Same as above, but the rules are applied to metrics from all metric sources.
* `metrics.<source>.allowList` - Sets a list of metrics that will be kept, dropping any metrics that don't match.
* `extraServices.prometheus.externalLabels` - A key-value set that defines labels and values to be set for all metrics
  being sent. It sets the `external_labels` section of
  [prometheus.remote_write](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.remote_write/#arguments)
  component.

### Delivery customizations

These fields adjust how metrics are actually delivered to the metrics service. Tyipcally, these will be changed only to
tune the performance of metrics uploads.

* `extraServices.prometheus.processors` - These processors control the batch and memory size of metrics to bundle
  before sending them to the service. Only applies to metrics services using the OTLP or OTLPHTTP protocols.
* `extraServices.prometheus.wal` - This controls the behavior of the Write Ahead Log that's used in the remote_write
  component.

## Logs

### Discovery customizations

When you customize the discovery of logs, it will affect which Pods to gather logs from. The default is all Pods in all namespaces,
but you can easily adjust this setting.

* `logs.pod_logs.namespaces` - Only gathers logs from Pods in the given list of namespaces.
* `logs.pod_logs.extraRelabelingRules` - Rules that filter from all Pods on the Cluster to the specific set
  that will be used for gathering logs. They're used to populate the rules section of a
  [discovery.relabel](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/) component.

### Gathering customizations

This field controls how Pod logs are gathered from the Cluster.

* `logs.pod_logs.gatherMethod` - The default method, "volumes", means that the Grafana Agent for logs will gather logs
  by mounting hostPath volumes to the pod log location on each Kubernetes Cluster Node. The other method, "api", means
  that the Agent will gather logs by streaming them from the Kubernetes API Server.

### Processing customizations

* `logs.pod_logs.extraStageBlocks` - Processing logs is done in stages. This field allows for additional stages to
  be set. Stages set here will be used to populate a
  [loki.process](https://grafana.com/docs/agent/latest/flow/reference/components/loki.process/) component.

## Events

### Discovery customizations

This field controls which namespaces to gather Cluster Events from.

* `logs.cluster_events.namespaces` - Only gather Cluster Events from the given list of namespaces.

### Processing customizations

* `logs.cluster_events.log_format` - Specifies the format of the Cluster events. Default is `logfmt`, but can also specify
  `json`.

## Additional Configuration

In addition to customizing the generated configuration, you can add new components to the the Kubernetes Monitoring Helm chart to define your own extra configuration.

* `extraConfig` - Config put here will be added to the config for the Grafana Agent StatefulSet that scraps metrics.
* `logs.extraConfig` - Config put here will be added to the config for the Grafana Agent for Logs.
