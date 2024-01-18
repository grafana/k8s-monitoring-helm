# Customizing the Configuration

By default, this chart provides a very capable configuration for Kubernetes Cluster infrastructure monitoring. However
there will be circumstances where you might want to customize the configuration. This document will describe the various
ways to provide those customizations and what affect they will have.

## Overview

Each telemetry data source (e.g. metrics, logs, events, traces) typically goes through the same process:

1. Discovery - How does the collector find the data source?
2. Scraping - How should the data get gathered?
3. Processing - What work needs to be done to the data?
4. Delivery - Where should the data be sent for storage?

## Metrics

Metrics are typically gathered using Prometheus-style scraping.

### Discovery customizations

These fields in the Helm chart's values affect how metric targets are discovered. Typically, you'll make changes here if
the Grafana Agent is not detecting the target.

* `metrics.<source>.extraRelabelingRules` - These rules are used to filter from all nodes, services, endpoints, or pods on the
  cluster to a specific one that has the metrics. They're used to populate the rules section of a
  [discovery.relabel](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/) component.
  Use these rules to target a specific service.
* `metrics.extraRelabelingRules` - Same as above, but these rules are applied to all metric sources.
* `metrics.<source>.labelMatchers` - This section is used to define what Kubernetes labels need to match on the target.
* `metrics.<source>.service.port` - This section defines the name of the port that has the metrics endpoint. 

### Scraping customizations

These fields in the Helm chart's values affect how metric targets are scraped. Typically, you'll make changes here if 
you want to change something about how 

* `metrics.<source>.scrapeInterval` - How often to scrape metrics from a target.
* `metrics.scrapeInterval` - Same as above, but changes the global default.
* `metrics.<source>.service.isTLS` - Should the Agent use HTTPS and TLS to scrape the target instead of HTTP?

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

* `extraServices.prometheus.processors` - These processors will control the batch and memory size of metrics to bundle
  before sending them to the service. Only applies to metrics services using the OTLP or OTLPHTTP protocols.

## Logs

### Discovery customizations

Customizing the discovery of logs will affect which Pods to gather logs from. The default is all pods in all namespaces,
but this can easily be adjusted.

* `logs.pod_logs.namespaces` - Only gather logs from pods in the given list of namespaces.
* `logs.pod_logs.extraRelabelingRules` - These rules are used to filter from all pods on the cluster to the specific set
  that will be used for gathering logs. They're used to populate the rules section of a
  [discovery.relabel](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/) component.

### Gathering customizations

* `logs.pod_logs.gatherMethod`

### Processing customizations

* `logs.pod_logs.extraRelabelingRules`

## Events

### Discovery customizations

`logs.cluster_events.namespaces` - Specify which namespaces to gather cluster events from.

## Additional Configuration



* `extraConfig`
* `logs.extraConfig`
