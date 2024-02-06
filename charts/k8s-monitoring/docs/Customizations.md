# Customizing the Configuration

Use the following to customize your configuration and understand how these customizations affect it.

## Overview

Each telemetry data source (e.g. metrics, logs, events, traces) typically goes through each of these phases:

1. Discovery - How does the collector find the data source?
2. Scraping - How should the data get gathered?
3. Processing - What work needs to be done to the data?
4. Delivery - Where should the data be sent for storage?

## Metrics

Metrics are usually gathered using Prometheus-style scraping.

###  Customize where to find the data

These fields affect how metric targets are discovered. If the Grafana Agent is not detecting the target, make changes to these values.

* `metrics.<source>.extraRelabelingRules` - These rules are used to populate the rules section of a
  [discovery.relabel](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/) component. They filter from all Nodes, services, endpoints, or Pods on the
Cluster to a specific one that has the metrics. 
  Use these rules to target a specific service.
* `metrics.extraRelabelingRules` - Same as above, but these rules are applied to all metric sources.
* `metrics.<source>.labelMatchers` - Defines what Kubernetes labels need to match on the target.
* `metrics.<source>.service.port` - Defines the name of the port that has the metrics endpoint. 

### Customize how to collect the data

These fields affect how metric targets are scraped. Typically, you'll make changes here if 
you want to change something about how often to scrape or which target to scrape.

* `metrics.<source>.scrapeInterval` - How often to scrape metrics from a target.
* `metrics.scrapeInterval` - Same as above, but changes the global default.
* `metrics.<source>.service.isTLS` - Determines whether the Agent use HTTPS and TLS to scrape the target instead of HTTP.

### Processing customizations

By default, we already use an "allow list" to filter to a specific set of metrics, meaning the list drops metrics that are not useful for monitoring Kubernetes Clusters. The following fields allow for more customizations of the metrics after they have been scraped, but before being sent to the external metric service for storage. Typical changes that you might want to do here include setting, modifying, or dropping metric labels.

* `metrics.<source>.extraMetricRelabelingRules` - Rules that modify metrics and will populate the rules
  section of a [prometheus.relabel](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/)
  component. Use these rules to perform arbitrary modifications to metrics or metric labels.
* `metrics.extraMetricRelabelingRules` - Same as above, but the rules are applied to metrics from all metric sources.
* `metrics.<source>.allowList` - Sets a list of metrics that will be kept, dropping any metrics that don't match.
* `extraServices.prometheus.externalLabels` - A key-value set that defines labels and values to be set for all metrics
  being sent. It sets the `external_labels` section of
  [prometheus.remote_write](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.remote_write/#arguments)
  component.

### Customize how metrics are uploaded

These fields adjust how metrics are delivered to the metrics service. Typically, change these only to
tune the performance of metrics uploads.

* `extraServices.prometheus.processors` - These processors control the batch and memory size of metrics to bundle
  before sending them to the service. Only applies to metrics services using the OTLP or OTLPHTTP protocols.
* `extraServices.prometheus.wal` - Controls the behavior of the Write Ahead Log that's used in the remote_write
  component.

## Logs

### Customize which logs to gather

The default for the Helm chart is to gather logs from all Pods in all namespaces. Use these settings to set which Pods you want logs collected from.

* `logs.pod_logs.namespaces` - Only gathers logs from Pods in the given list of namespaces.
* `logs.pod_logs.extraRelabelingRules` - Rules that filter from all Pods on the Cluster to the specific set
  that will be used for gathering logs. They're used to populate the rules section of a
  [discovery.relabel](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/) component.

### Gathering customizations

This field controls how Pod logs are gathered from the Cluster.

* `logs.pod_logs.gatherMethod` - The default method, "volumes", means that the Grafana Agent for logs will gather logs
  by mounting hostPath volumes to the Pod log location on each Kubernetes Cluster Node. The other method, "api", means
  that the Agent will gather logs by streaming them from the Kubernetes API Server.

### Customize how logs are processed

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
