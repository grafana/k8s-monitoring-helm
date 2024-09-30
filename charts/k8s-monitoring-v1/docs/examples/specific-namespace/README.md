# Specific Namespace

This example shows how to modify things to only scrape metrics and logs from a specific set of namespaces.

Metrics and logs can both be adjusted to filter to a specific namespace.

-   Metrics: This is done with a metric relabeling rule. We cannot pre-filter scrape targets, because many of the systems that generate metrics do not live in the same namespace as the applications that we want to observe. NOTE: we want to keep metrics with an empty or missing namespace label, because we do not want to filter out non-namespaced metrics.
-   Prometheus Operator objects: This is done by filtering which namespaces to look for these objects. This could also be done in those objects themselves.
-   Logs: This is done with a list of namespaces, which translates into a log processing filter
-   Cluster Events: This is done with a list of namespaces, which is sent to the cluster event discovery object itself.

```yaml
cluster:
  name: specific-namespace-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

metrics:
  extraMetricRelabelingRules: |-
    rule {
        source_labels = ["namespace"]
        regex = "^$|production|staging"
        action = "keep"
    }

  podMonitors:
    namespaces: [production, staging]

  probes:
    namespaces: [production, staging]

  serviceMonitors:
    namespaces: [production, staging]

logs:
  pod_logs:
    namespaces: [production, staging]

  cluster_events:
    namespaces:
      - production
      - staging
```
