<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# GKE with TPUs

On GKE nodes that have [TPUs](https://cloud.google.com/kubernetes-engine/docs/how-to/tpus), GKE runs a managed
`tpu-device-plugin` DaemonSet in the `kube-system` namespace (labeled `k8s-app=tpu-device-plugin`) that exposes
node-level TPU metrics on port 2112.

The chart does not scrape this component automatically, so this test adds an `extraConfig` block that discovers the
`tpu-device-plugin` pods and scrapes their TPU metrics and forwarding them to the metrics destination.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: gke-tpu-test

destinations:
  grafana-cloud-metrics:
    type: prometheus
    url: https://prometheus-prod-13-prod-us-east-0.grafana.net/api/prom/push
    auth:
      type: basic
      usernameKey: PROMETHEUS_USER
      passwordKey: PROMETHEUS_PASS
    secret:
      create: false
      name: grafana-cloud-credentials
      namespace: default

collectors:
  alloy:
    presets: [clustered, statefulset]
    # Discover and scrape TPU metrics from the GKE-managed tpu-device-plugin. On any node with a
    # TPU, GKE runs the tpu-device-plugin DaemonSet in kube-system (labeled k8s-app=tpu-device-plugin)
    # which exposes node-level TPU metrics (duty_cycle_node, tensorcore_utilization_node,
    # memory_used_node, memory_total_node, memory_bandwidth_utilization_node, ...) on port 2112.
    includeDestinations: [grafana-cloud-metrics]
    extraConfig: |-
      discovery.kubernetes "tpu_device_plugin" {
        role = "pod"
        namespaces {
          names = ["kube-system"]
        }
        selectors {
          role  = "pod"
          label = "k8s-app=tpu-device-plugin"
        }
      }

      discovery.relabel "tpu_device_plugin" {
        targets = discovery.kubernetes.tpu_device_plugin.targets

        // The tpu-device-plugin serves Prometheus metrics on port 2112. Point every target at the
        // pod IP on that port so this works whether or not the container declares a named port.
        rule {
          source_labels = ["__meta_kubernetes_pod_ip"]
          regex         = "(.+)"
          replacement   = "$1:2112"
          target_label  = "__address__"
        }
        rule {
          source_labels = ["__meta_kubernetes_namespace"]
          target_label  = "namespace"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_name"]
          target_label  = "pod"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_node_name"]
          target_label  = "instance"
        }
      }

      prometheus.scrape "tpu_metrics" {
        job_name   = "integrations/tpu"
        targets    = discovery.relabel.tpu_device_plugin.output
        forward_to = [prometheus.remote_write.grafana_cloud_metrics.receiver]
      }
```
<!-- textlint-enable terminology -->
