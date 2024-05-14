# Additional Configuration with `extraConfig`

The Kubernetes Monitoring Helm chart has the ability to supply additional configuration to the Grafana Alloy instances
using the `extraConfig` sections. Anything put in these sections are added to the existing configuration that is created
by this chart. There are a few methods to use these sections that will be explored in this document.

## Different sections

There are two `extraConfig` sections that you can use:

-   `.extraConfig` Inserts configuration for the Grafana Alloy instance that scrapes metrics and opens receivers.
-   `.logs.extraConfig` Inserts configuration for the Grafana Alloy instance that gathers logs.

## How to use

Helm provides multiple ways to set these additional configuration values. Either keep the values in the same file as the
rest of your Kubernetes Monitoring configuration, or store them separately as their own files and include during Helm
chart install.

### Set as values

You can set the contents of your extra configuration into your values file:

```shell
$ ls
values.yaml
$ cat values.yaml
cluster:
  name: my-cluster
...
extraConfig: |
  logging {
    level  = "debug"
  }
...
logs:
...
  extraConfig: |
    logging {
      level  = "debug"
    }
...
$ helm upgrade grafana-k8s-monitoring --atomic --timeout 300s grafana/k8s-monitoring --values values.yaml
```

For another example, see [Service Integrations](../../../examples/service-integrations).

### Set as files

You can save the contents of your extra configuration as files and use Helm's `--set-file` argument:

```shell
$ ls
values.yaml  metricsConfig.alloy  logsConfig.alloy
$ helm upgrade grafana-k8s-monitoring --atomic --timeout 300s grafana/k8s-monitoring \
    --values values.yaml \
    --set-file extraConfig=metricsConfig.alloy \
    --set-file logs.extraConfig=logsConfig.alloy
```

This can be beneficial once your extra configuration grows to a certain size.
