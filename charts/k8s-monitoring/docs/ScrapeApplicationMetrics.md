# Scraping Additional Metrics

If you have an application or a service running on your Kubernetes Cluster that is exporting metrics, you can  
use this chart to scrape those metrics and send them to your datastore. This chart provides plenty of options for doing
just that.

## Options

1. Use the `k8s.grafana.com/scrape` annotation on your Pods or services.
2. Use Prometheus Operator CRDs, like ServiceMonitors, PodMonitors, or Probes.
3. Make a custom Grafana Agent Flow configuration.

## Annotations

This chart configures the Grafana Agent to look for Pods and Services that have the `k8s.grafana.com/scrape` annotation
set. When set, the Agent scrapes them for metrics.

Extra annotations can also be set to control the behavior of the discovery and scraping of the metrics:

* `k8s.grafana.com/job: <string>` - Sets the job label.
* `k8s.grafana.com/instance: <string>` - Sets the instance label.
* `k8s.grafana.com/metrics.path: <string>` - Sets the metrics path. Required if the metrics path is not the default
  of `/metrics`.
* `k8s.grafana.com/metrics.portName: <string>` - Specifies the port to scrape, by name. This named port must exist on
  the pod or service.
* `k8s.grafana.com/metrics.portNumber: <number>` - Specifies to port to scrape, by number.
* `k8s.grafana.com/metrics.scheme: [http|https]` - Sets the scheme to use. Required if the scheme is not HTTP.

The chart itself provides additional options:

* `metrics.autoDiscover.extraRelabelingRules` - Use relabeling rules to filter the Pods or services to scrape.
* `metrics.autoDiscover.metricsTuning` - Specify which metrics to keep or drop.
* `metrics.autoDiscover.extraMetricRelabelingRules` - Use relabeling rules to process the metrics after scraping them.

These values apply to all discovered Pods and services.

## Prometheus Operator CRDs

By default, this chart configures the Grafana Agent to detect and utilize ServiceMonitors, PodMonitors, and Probes. If
any of those objects are detected on your Cluster, the Agent will utilize them to extend its configuration.

For more information about creating and configuring these options, refer to
the [Prometheus Operator Documentation](https://github.com/prometheus-operator/prometheus-operator).

This chart provides ways to customize how the Agent handles these objects.

### Controlling discovery

These options in the Helm chart allow for changing how Prometheus Operator objects are discovered:

* `metrics.serviceMonitors.enabled` - If set to true, the Agent looks for and consumes ServiceMonitors.
* `metrics.serviceMonitors.namespaces` - Only use ServiceMonitors that exist in these namespaces.
* `metrics.serviceMonitors.selector` - Use
  a [selector](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.operator.servicemonitors/#selector-block)
  block to provide a more refined selection of objects.

The same options are present for `metrics.podmonitors` and `metrics.probes`.

### Controlling scraping

Most of the scrape configuration is embedded in the Prometheus Operator object itself.

* `metrics.serviceMonitors.scrapeInterval` - Sets the scrape interval, if one was not specified in the object.

The same option is present for `metrics.podmonitors` and `metrics.probes`.

### Controlling processing

This chart can set metrics relabeling rules for processing the metrics after scraping them.

* `metrics.serviceMonitors.extraMetricRelabelingRules` - Sets post-scraping rules for
  a [prometheus.relabel](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/)
  configuration component.

The same option is present for `metrics.podmonitors` and `metrics.probes`.

## Custom Agent Config

This option allows for the greatest amount of flexibility and utility.

When adding new configuration, it's helpful to think of it in four phases:

1. Discovery - How should the collector find my service?
2. Scraping - How should metrics get scraped from my service?
3. Processing - Is there any work that needs to be done to these metrics?
4. Delivery - Where should these metrics be sent?

We will go deeper into each phase below.

## Discovery

The discovery phase is about finding the specific pod or service that needs to be scraped for metrics.

This chart automatically creates three components that you can utilize:

* `discovery.kubernetes.nodes` - Discovers all nodes in the cluster
* `discovery.kubernetes.services` - Discovers all services in the cluster
* `discovery.kubernetes.endpoints` - Discovers all service endpoints in the cluster
* `discovery.kubernetes.pods` - Discovers all pods in the cluster

These are
all [`discovery.kubernetes`](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.kubernetes/)
components which gather all the specific resources using the Kubernetes API. From here, you want to refine the search
to the service or the Pod that you want.

### Service discovery

Since you don't want to scrape every service in your Cluster, use rules to select your specific service based
on its name, namespace, labels, port names or numbers, and many other variables.
To do so, use 
a [`discovery.relabel`](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/)
component and add one or more rules, using special meta-labels that are set automatically by the
`discovery.kubernetes` component.

Here is an example component that we've named "blue_database_service". This component takes the list of all services
from `discovery.kubernetes.services` and filters to a service named "database", in the namespace "blue", with the port
named "metrics":

```river
discovery.relabel "blue_database_service" {
  targets = discovery.kubernetes.services.targets  // Gets all services
  rule {  // Keep all services named "database"...
    source_labels = ["__meta_kubernetes_service_name"]
    regex = "database"
    action = "keep"
  }
  rule {  // ... that exist in the "blue" namespace...
    source_labels = ["__meta_kubernetes_namespace"]
    regex = "blue"
    action = "keep"
  }
  rule {  // ... and only scrape its port named "metrics".
    source_labels = ["__meta_kubernetes_service_port_name"]
    regex = "metrics"
    action = "keep"
  }
}
```

The [documentation](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.kubernetes/#service-role)
has the list of meta labels for services. Note that there are different labels for port name and port number. Make sure
you use the right label for a named port or simply the port number.

This is also a good place to add any extra labels that will be scraped. For example, if you wanted to set the label
`team="blue"`, you might use this additional rule in the `blue_database_service` component we just made:

```river
  rule {
    target_label = "team"
    action = "replace"
    replacement = "blue"
  }
```

### Pod discovery

Similar to service discovery, use
a [`discovery.relabel`](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/)
component to select the specific Pod you want to scrape.
The [meta labels for pods](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.kubernetes/#pod-role)
will be slightly different, but the concept is the same.

Here is an example that filters to a specific set of Pods that starts with name "analysis", with the label
"system.component=image":

```river
discovery.relabel "image_analysis_pods" {
  targets = discovery.kubernetes.pods.targets  // Gets all pods
  rule {  // Keep all pods named "analysis.*"...
    source_labels = ["__meta_kubernetes_pod_name"]
    regex = "analysis.*"
    action = "keep"
  }
  rule {  // ... with the label system.component=image
    source_labels = ["__meta_kubernetes_pod_label_system_component"]
    regex = "image"
    action = "keep"
  }
}
```

Note that there is a unique meta label for every Kubernetes label. The labels are prefixed with
`__meta_kubernetes_pod_label_` and the label name is normalized so all non-alphanumeric characters become underscores
(`_`).

## Scraping

Now that you've selected the specific pod or service you want, you can scrape it for metrics. Do this with the
[`prometheus.scrape`](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.scrape/) component. Essentially,
 you only need to declare what things to scrape and where to send
the scraped metrics. Here is an example:

```river
prometheus.scrape "processing_app" {
  targets = discovery.relabel.image_analysis_pods.output
  forward_to = [prometheus.relabel.metrics_service.receiver]
}
```

Note that we will cover the `forward_to` field in the [Delivery](#delivery) section below.

This component gives a lot of flexibility to modify how things are scraped, including setting the `job` label, how
frequently the metrics should be scraped, the path to scrape, and many more. Here is an example with lots of options:

```river
prometheus.scrape "processing_app" {
  targets = discovery.relabel.image_analysis_pods.output
  job_name = "integrations/processing"
  scrape_interval = "120s"
  metrics_path = "/api/v1/metrics"
  forward_to = [prometheus.relabel.metrics_service.receiver]
}
```

## Processing

Often, you want to perform some post-scrape processing to the metrics. Some common reasons are to:

* Limit the amount of metrics being sent up to Prometheus.
* Add, change, or drop labels.

Processing is done with the
[`prometheus.relabel`](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.relabel/)
component. It uses the same type of rules as `discovery.relabel`, but instead of filtering scrape _targets_, it filters
the _metrics_ that were scraped.

Here is an example of processing that filters down the scraped metrics to only `up` and anything that starts with
`processor` (thus, dropping all other metrics):

```river
prometheus.scrape "processing_app" {
  targets = discovery.relabel.image_analysis_pods.output
  forward_to = [prometheus.relabel.processing_app.receiver]
}

prometheus.relabel "processing_app" {
  rule {
    source_labels = ["__name__"]
    regex = "up|processor.*"
    action = "keep"
  }
  forward_to = [prometheus.relabel.metrics_service.receiver]
}
```

Note that the `prometheus.scrape` component needs to be adjusted to forward to this component.

## Delivery

The `prometheus.scrape` and `prometheus.relabel` components need to send their outputs to another component. This is the
purpose of their `forward_to` field. Forwarding can be to another `prometheus.relabel` component, but eventually, the final
step is to send the metrics to a Prometheus server for storage, where it can be further processed by recording rules, or
queried and displayed by Grafana. For this, use 
the [`prometheus.remote_write`](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.remote_write/)
component.

This chart automatically creates the component `prometheus.relabel.metrics_service`, configured by the
`.externalServices.prometheus` values. You can use this component to send your metrics to the same destination as the
infrastructure metrics.

If you want to use an alternative destination, you can create a new `prometheus.remote_write` component.

## Putting it all together

The easiest way to include your configuration into this chart is to save it into a file and pass it directly to the
`helm install` command:

```text
$ ls
processor-config.river chart-values.yaml
$ cat processor_config.river
discovery.relabel "image_analysis_pods" {
  targets = discovery.kubernetes.pods.targets  // Gets all pods
  rule {  // Keep all pods named "analysis.*"...
    source_labels = ["__meta_kubernetes_pod_name"]
    regex = "analysis.*"
    action = "keep"
  }
  rule {  // ... with the label system.component=image
    source_labels = ["__meta_kubernetes_pod_label_system_component"]
    regex = "image"
    action = "keep"
  }
}

prometheus.scrape "processing_app" {
  targets = discovery.relabel.image_analysis_pods.output
  forward_to = [prometheus.relabel.processing_app.receiver]
}

prometheus.relabel "processing_app" {
  rule {
    source_labels = ["__name__"]
    regex = "up|processor.*"
    action = "keep"
  }
  forward_to = [prometheus.relabel.metrics_service.receiver]
}
$ helm upgrade --install grafana-k8s-monitoring --atomic --timeout 300s grafana/k8s-monitoring --values chart-values.yaml --set-file extraConfig=processor-config.river
```

For more information about using the `extraConfig` values, see [the documentation](UsingExtraConfig.md).
