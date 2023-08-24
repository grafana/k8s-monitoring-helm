# Scraping Metrics from an Application

If you have an application, running on your Kubernetes cluster, that is exporting metrics you can easily extend the
configuration in this chart to scrape and forward those metrics.

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
* `discovery.kubernetes.pods` - Discovers all pods in the cluster
* `discovery.kubernetes.services` - Discovers all services in the cluster

These are all [`discovery.kubernetes`](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.kubernetes/)
components, which gather all the specific resources, using the Kubernetes API. From here, we want to refine the search to just the service or the pod that we want.

### Service discovery

Since you don't want to scrape every service in your cluster, you will use rules to select your specific service based
on its name, namespace, labels, port names or numbers, and many other variables.
This is done by using a [`discovery.relabel`](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/)
component and adding one or more rules, using special meta-labels that are set automatically by the
`discovery.kubernetes` component.

Here is an example that filters to a service named "database", in the namespace "blue", with the port named "metrics":

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
has the list of meta labels for services. 

This is also a good place to add any extra labels that will be scraped. For example, if you wanted to set the label
`team="blue"`, you might use this additional rule:

```river
  rule {
    target_label = "team"
    action = "replace"
    replacement = "blue"
  }
```

### Pod discovery

Similar to service discovery, we use a [`discovery.relabel`](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.relabel/)
component to select the specific pod or pods that we want to scrape. The [meta labels for pods](https://grafana.com/docs/agent/latest/flow/reference/components/discovery.kubernetes/#pod-role)
will be slightly different, but the concept is the same.

Here is an example that filters to a specific set of pods that starts with name "analysis", with the label "system.component=image":

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
`__meta_kubernetes_pod_label_` and the label name is normalized so all non-alphanumeric characters become underscores (`_`).

## Scraping

Now that we've selected the specific pod or service we want, we can scrape it for metrics. This is done with the
[`prometheus.scrape`](https://grafana.com/docs/agent/latest/flow/reference/components/prometheus.scrape/) component.

...

```river
prometeus.scrape "processing_app" {
  targets = discovery.relabel.image_analysis_pods.targets
  forward_to = ...
}
```

...

## Processing

...

## Delivery

...

