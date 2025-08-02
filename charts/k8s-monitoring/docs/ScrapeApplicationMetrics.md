# Scraping Additional Metrics

If you have an application or a service running on your Kubernetes Cluster that is exporting Prometheus metrics, you can
use this chart to scrape those metrics and send them to your datastore. This document explains several options to
accomplish this.

## Options

1.  Use the `k8s.grafana.com/scrape` annotation on your Pods or services.
2.  Use Prometheus Operator CRDs, like ServiceMonitors, PodMonitors, or Probes.
3.  Make a custom Grafana Alloy configuration.

## Annotations

You can use the [Annotation Autodiscovery](../charts/feature-annotation-autodiscovery) feature to look for Pods and
Services that have the `k8s.grafana.com/scrape` annotation set. When set, the Alloy instance scrapes them for metrics.

Extra annotations can also be set to control the behavior of the discovery and scraping of the metrics:

-   `k8s.grafana.com/job: <string>` - Sets the job label.
-   `k8s.grafana.com/instance: <string>` - Sets the instance label.
-   `k8s.grafana.com/metrics.path: <string>` - Sets the metrics path. Required if the metrics path is not the default
  of `/metrics`.
-   `k8s.grafana.com/metrics.portName: <string>` - Specifies the port to scrape, by name. This named port must exist on
  the pod or service.
-   `k8s.grafana.com/metrics.portNumber: <number>` - Specifies to port to scrape, by number.
-   `k8s.grafana.com/metrics.scheme: [http|https]` - Sets the scheme to use. Required if the scheme is not HTTP.

The chart itself provides additional options:

-   `annotationAutodiscovery.extraDiscoveryRules` - Use relabeling rules to filter the Pods or services to scrape.
-   `annotationAutodiscovery.metricsTuning` - Specify which metrics to keep or drop.
-   `annotationAutodiscovery.extraMetricProcessingRules` - Use relabeling rules to process the metrics after scraping
  them.

These values apply to all discovered Pods and services. Refer to the
[feature documentation](../charts/feature-annotation-autodiscovery) to learn about all the possible options.

## Prometheus Operator CRDs

You can use the [Prometheus Operator Objects](../charts/feature-prometheus-operator-objects) feature to detect and
utilize ServiceMonitor, PodMonitor, and Probe objects on the Kubernetes cluster. If any of those objects are detected,
Alloy will utilize them to extend its configuration.

For more information about creating and configuring these options, refer to
the [Prometheus Operator Documentation](https://github.com/prometheus-operator/prometheus-operator).

This chart provides ways to customize how Alloy handles these objects.

### Controlling discovery

To change how Prometheus Operator objects are discovered, use these options in the Helm chart:

-   `prometheusOperatorObjects.serviceMonitors.enabled` - If set to true, Alloy looks for and consumes ServiceMonitors.
-   `prometheusOperatorObjects.serviceMonitors.namespaces` - Only use ServiceMonitors that exist in these namespaces.
-   `prometheusOperatorObjects.serviceMonitors.selector` - Use
  a [selector](https://grafana.com/docs/alloy/latest/reference/components/prometheus.operator.servicemonitors/#selector-block)
  block to provide a more refined selection of objects.

The same options are present for `prometheusOperatorObjects.podmonitors` and `prometheusOperatorObjects.probes`.

### Controlling scraping

Most of the scrape configuration is embedded in the Prometheus Operator object itself.

-   `prometheusOperatorObjects.serviceMonitors.scrapeInterval` - Sets the scrape interval, if one was not specified in the
  object.

The same option is present for `prometheusOperatorObjects.podmonitors` and `prometheusOperatorObjects.probes`.

### Controlling processing

This chart can set metrics relabeling rules for processing the metrics after scraping them.

-   `prometheusOperatorObjects.serviceMonitors.extraMetricRelabelingRules` - Sets post-scraping rules for
  a [prometheus.relabel](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/)
  configuration component.

The same option is present for `prometheusOperatorObjects.podmonitors` and `prometheusOperatorObjects.probes`.

## Custom Alloy Config

This option allows for the greatest amount of flexibility and utility.

When adding new configuration, it's helpful to think of it in four phases:

1.  Discovery - How should the collector find my service?
2.  Scraping - How should metrics get scraped from my service?
3.  Processing - Is there any work that needs to be done to these metrics?
4.  Delivery - Where should these metrics be sent?

We will go deeper into each phase below.

## Discovery

The discovery phase is about finding the specific pod or service that needs to be scraped for metrics.

To get started, you can use the
[`discovery.kubernetes`](https://grafana.com/docs/alloy/latest/reference/components/discovery.kubernetes/) component to
discover specific resources in your Kubernetes Cluster. This component uses the Kubernetes API to discover pods,
services,
endpoints, nodes, and more.

This component can also pre-filter the discovered resources based on their namespace, labels, and other selectors. This
is recommended, because it'll greatly reduce the CPU and memory usage of the Alloy instance, as it will not need to
filter through the resources in the relabeling compnent later.

Here is an example component that we've named "blue_database_service". This component takes the list of all services
from `discovery.kubernetes.services` and filters to a service named "database", in the namespace "blue", with the port
named "metrics":

```grafana-alloy
discovery.kubernetes "blue_database_service" {
  role = "service"    // This component will return services...
  namespaces {
    names = ["blue"]  // ... that exist in the "blue" namespace
  }
  
  selector {
    role = "service"
    label = "app.kubernetes.io/name=db"  // ... and have the label "app.kubernetes.io/name=db"
  }
}
```

### Service discovery

You'll likely need to do additional filtering after discovering components with the `discovery.kubernetes`
component. You can use rules to select your specific service based on its name, namespace, labels, port names or
numbers, and many other variables. To do so, use
a [`discovery.relabel`](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/)
component and add one or more rules, using meta-labels that are set automatically by the
`discovery.kubernetes` component and always start with `__`.

Here, we're continuing our example and will add a `discovery.relabel` component. This component takes the list of
services from our `discovery.kubernetes` component and further filters them to return only the one with the port named
"metrics":

```grafana-alloy
discovery.relabel "blue_database_service" {
  targets = discovery.kubernetes.blue_database_service.targets  // Gets our service from before...
  rule {  // ... and only scrape its port named "metrics".
    source_labels = ["__meta_kubernetes_service_port_name"]
    regex = "metrics"
    action = "keep"
  }
}
```

The [documentation](https://grafana.com/docs/alloy/latest/reference/components/discovery.kubernetes/#service-role)
has the list of meta labels for services. Note that there are different labels for port name and port number. Make sure
you use the right label for a named port or the port number.

This is also a good place to add any extra labels that will be added to the metrics after scraping. For example, if you
wanted to set the label `team="blue"`, you might use this additional rule in the `blue_database_service` component:

```grafana-alloy
  rule {
    target_label = "team"
    action = "replace"
    replacement = "blue"
  }
```

### Pod discovery

Similar to service discovery, use
a [`discovery.kubernetes`](https://grafana.com/docs/alloy/latest/reference/components/discovery.kubernetes/) component
and a [`discovery.relabel`](https://grafana.com/docs/alloy/latest/reference/components/discovery.relabel/) component to
select the specific Pod you want to scrape.
The [meta labels for pods](https://grafana.com/docs/alloy/latest/reference/components/discovery.kubernetes/#pod-role)
will be slightly different, but the concept is the same.

Here is an example that filters to a specific set of Pods that starts with name "analysis", with the label
"system.component=image":

```grafana-alloy
discovery.kubernetes "image_analysis_pods" {
  role = "pod"

  selector {
    role = "pod"
    label = "system.component=image"
  }
}

discovery.relabel "image_analysis_pods" {
  targets = discovery.kubernetes.image_analysis_pods.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    regex = "analysis.*"
    action = "keep"
  }
}
```

Note that there is a unique meta label for every Kubernetes label. The labels are prefixed with
`__meta_kubernetes_pod_label_` and the label name is normalized so all non-alphanumeric characters become underscores
(`_`).

## Scraping

Now that you've selected the specific pod or service you want, you can scrape it for metrics. Do this with the
[`prometheus.scrape`](https://grafana.com/docs/alloy/latest/reference/components/prometheus.scrape/) component.
Essentially, you only need to declare what targets to scrape and where to send the scraped metrics. Here is an example:

```grafana-alloy
prometheus.scrape "processing_app" {
  targets = discovery.relabel.image_analysis_pods.output
  forward_to = [prometheus.relabel.metrics_service.receiver]
}
```

Note that the `forward_to` field in the [Delivery](#delivery) is explained in a subsequent section of this document.

This component gives a lot of flexibility to modify how things are scraped, including setting the `job` label, how
frequently the metrics should be scraped, the path to scrape, and many more. Here is an example with lots of options:

```grafana-alloy
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

-   Limit the amount of metrics being sent up to Prometheus.
-   Add, change, or drop labels.

Processing is done with the
[`prometheus.relabel`](https://grafana.com/docs/alloy/latest/reference/components/prometheus.relabel/)
component. It uses the same type of rules as `discovery.relabel`, but instead of filtering scrape _targets_, it filters
the _metrics_ that were scraped.

Here is an example of processing that filters down the scraped metrics to only `up` and anything that starts with
`processor` (thus, dropping all other metrics):

```grafana-alloy
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
purpose of their `forward_to` field. Forwarding can be to another `prometheus.relabel` component, but eventually, the
final step is to send the metrics to a Prometheus server for storage, where it can be further processed by recording
rules, or queried and displayed by Grafana. For this, use
the [`prometheus.remote_write`](https://grafana.com/docs/alloy/latest/reference/components/prometheus.remote_write/)
component.

This chart automatically creates components for your metrics destinations, configured by the `.destinations` values. The
names for these components are derived from the destination name and type:

| Destination name         | Destination type | Component name                                            |
|--------------------------|------------------|-----------------------------------------------------------|
| `My Metrics Destination` | `prometheus`     | `prometheus.remote_write.my_metrics_destination.receiver` |
| `otlp-endpoint`          | `otlp`           | `otelcol.receiver.prometheus.otlp_endpoint.receiver`      |

Note that the component name uses lowercase and replaces non-alphanumeric characters with underscores (`_`).

## Putting it all together

The easiest way to include your configuration into this chart is to save it into a file and pass it directly to the
`helm install` command:

```text
$ ls
processor-config.alloy chart-values.yaml
$ cat processor_config.alloy
discovery.kubernetes "image_analysis_pods" {
  role = "pod"

  selector {
    role = "pod"
    label = "system.component=image"
  }
}

discovery.relabel "image_analysis_pods" {
  targets = discovery.kubernetes.image_analysis_pods.targets
  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    regex = "analysis.*"
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
$ head chart-values.yaml
cluster:
  name: my-cluster

destinations:
  - name: metrics-service
    type: prometheus
    url: https://my-metrics-destination.example.com/api/v1/write
$ helm upgrade --install grafana-k8s-monitoring grafana/k8s-monitoring --values chart-values.yaml --set-file "alloy-metrics.extraConfig=processor-config.alloy"
```

For more information about using the `extraConfig` values, see [the documentation](UsingExtraConfig.md).
