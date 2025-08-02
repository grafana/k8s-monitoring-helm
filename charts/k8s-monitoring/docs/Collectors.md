# Collectors

Collectors are Alloy instances deployed by the Alloy Operator as Kubernetes workloads. Each collector uses a
workload type appropriate for the telemetry type it collects.

## General configuration

Each collector is defined in its own section in the Kubernetes Monitoring Helm chart values file. Here is an example of
the general format to enable and configure a collector:

```yaml
alloy-<collector name>:
  enabled: true  # Enable deploying this collector

  alloy:  # Settings related to the Alloy instance
    ...
  controller:  # Settings related to the Alloy controller
    ...
```

This creates a Kubernetes workload as either a DaemonSet, StatefulSet, or Deployment, with its own set of Pods running
Alloy containers.

Because collectors are deployed using the Alloy Operator, you can use any of the
standard [Alloy helm chart values](https://raw.githubusercontent.com/grafana/alloy/refs/heads/main/operations/helm/charts/alloy/values.yaml).
These values will be used when creating the Alloy instance.

Options specific to the Kubernetes Monitoring Helm chart are described in the following reference section.

## Alloy Receiver

-   **Pods Name**: `<helm_release>-alloy-receiver-*`
-   **Default Controller Type**: DaemonSet
-   **Service Name**: `<helm_release_name>-alloy-receiver`

This collector creates an Alloy instance deployed as a DaemonSet to receive application metrics when
the [Application Observability](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability)
feature is enabled.

For each
[receiver](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability#receivers-jaeger)
enabled in the feature, configure this collector to expose the corresponding ports on the Kubernetes service that is
fronting the Pods. For example, to enable a receiver to collect Zipkin traces, add:

```yaml
applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true
        port: 4317
      http:
        enabled: true
        port: 4318

...
alloy-receiver:
  enabled: true
  alloy:
    extraPorts:
      - name: otlp-grpc
        port: 4317
        targetPort: 4317
        protocol: TCP
      - name: otlp-http
        port: 4318
        targetPort: 4318
        protocol: TCP
```

### Client endpoint configuration

You can configure endpoints inside or outside the Cluster.

#### Inside the Cluster

Applications inside the Kubernetes Cluster can use
the [kubedns](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#namespaces-of-services) name to
reference a particular receiver endpoint. For example:

```yaml
endpoint: http://grafana-k8s-monitoring-alloy[.mynamespace.cluster.local]:4318
```

#### Outside the Cluster

To expose the receiver to applications outside the Cluster (for example, for frontend observability), you can use
different approaches depending on your setup. Load balancers are created by whatever controllers are installed on your
Cluster. Make sure to check
the [Alloy chart values](https://raw.githubusercontent.com/grafana/alloy/main/operations/helm/charts/alloy/values.yaml)
for the full list of options.

For example, to create a NLB on AWS EKS when using the AWS LB controller:

```yaml
alloy-receiver:
  alloy:
    service:
      type: LoadBalancer
```

To create an ALB instead:

```yaml
alloy-receiver:
  alloy:
    ingress:
      enabled: true
      path: /
      faroPort: 12347
```

You can also create additional services and ingress objects as needed if the Alloy chart options don't fit your needs.
Consult your Kubernetes vendor documentation for details.

### Istio/Service Mesh

Depending on your mesh configuration, you might need to explicitly include the Grafana monitoring namespace as a member,
or declare the Alloy instance as a backend of your application for traffic within the Cluster.

For traffic from outside the Cluster, you likely need to set up an ingress gateway into your mesh.

In any case, consult your mesh vendor for details.

## Troubleshooting

Here are some troubleshooting tips related to configuring collectors.

### Startup issues

Make sure your Pods are up and running. To do so, use this command to show you a list of Pods and associated states:

`kubectl get pods -n <helm_release_namespace>`

While you may have meta-monitoring turned on (which would expose the Alloy Pod logs in Loki), this is not helpful when
the alloy-logs instance itself is faulty.

To troubleshoot startup problems, you can inspect the Pod
logs [like any other Kubernetes workload](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_logs/). To
watch the alloy-logs instance Pods:

`kubectl logs -f --tail 100 ds/grafana-k8s-monitoring-alloy-logs`

### Alloy debugger

You can apply [standard Alloy troubleshooting strategies](https://grafana.com/docs/alloy/latest/troubleshoot/) to each
collector pod, but specifically for Kubernetes.

1.  To access the Alloy UI on a collector Pod, forward the UI port to your local machine:

    ```bash
    kubectl port-forward grafana-k8s-monitoring-alloy-receiver 12345:12345
    ```

2.  Open your browser to `http://localhost:12345`

## Scaling

Follow these instructions for appropriate scaling.

### DaemonSets and Singleton instances

For collectors deployed as DaemonSets and Singleton instances, one Pod is deployed per Node. You cannot deploy more
replicas with this type of controller. Instead, scale the individual Pods by increasing the resource requests and
limits. Refer to
the [Alloy helm chart sizing guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) to
learn how to best tune those parameters. For example:

```yaml
alloy-metrics:
  alloy:
    resources:
      requests: {}
      limits: {}
```

### StatefulSets

For StatefulSet collectors, set the number of replicas in the `alloy` config section of the collector:

```yaml
alloy-metrics:
  controller:
    replicas: 3
```

### Autoscaling

**Use with caution as Autoscalers can cause Cluster outtages when not configured properly.**

Alloy doesn't provide autoscaling out of the box, but you can use the
Kubernetes [HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
and [VPA](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) autoscalers, depending on the type of deployment for the collector. Set the target for the
HorizontalPodAutoscaler or VerticalPodAutoscaler to the collector deployment name.

## Values reference

### Alloy Logs

| Key                                       | Type   | Default       | Description                                                                              |
|-------------------------------------------|--------|---------------|------------------------------------------------------------------------------------------|
| alloy-logs.controller.type                | string | `"daemonset"` | The type of controller to use for the Alloy Logs instance.                               |
| alloy-logs.enabled                        | bool   | `false`       | Deploy the Alloy instance for collecting log data.                                       |
| alloy-logs.extraConfig                    | string | `""`          | Extra Alloy configuration to be added to the configuration file.                         |
| alloy-logs.liveDebugging.enabled          | bool   | `false`       | Enable live debugging for the Alloy instance.                                            |
| alloy-logs.logging.format                 | string | `"logfmt"`    | Format to use for writing Alloy log lines.                                               |
| alloy-logs.logging.level                  | string | `"info"`      | Level at which Alloy log lines should be written.                                        |
| alloy-logs.remoteConfig.auth.password     | string | `""`          | The password to use for the remote config server.                                        |
| alloy-logs.remoteConfig.auth.passwordFrom | string | `""`          | Raw config for accessing the password.                                                   |
| alloy-logs.remoteConfig.auth.passwordKey  | string | `"password"`  | The key for storing the username in the secret.                                          |
| alloy-logs.remoteConfig.auth.type         | string | `"none"`      | The type of authentication to use for the remote config server.                          |
| alloy-logs.remoteConfig.auth.username     | string | `""`          | The username to use for the remote config server.                                        |
| alloy-logs.remoteConfig.auth.usernameFrom | string | `""`          | Raw config for accessing the username.                                                   |
| alloy-logs.remoteConfig.auth.usernameKey  | string | `"username"`  | The key for storing the username in the secret.                                          |
| alloy-logs.remoteConfig.enabled           | bool   | `false`       | Enable fetching configuration from a remote config server.                               |
| alloy-logs.remoteConfig.extraAttributes   | object | `{}`          | Attributes to be added to this collector when requesting configuration.                  |
| alloy-logs.remoteConfig.pollFrequency     | string | `"5m"`        | The frequency at which to poll the remote config server for updates.                     |
| alloy-logs.remoteConfig.proxyURL          | string | `""`          | The proxy URL to use of the remote config server.                                        |
| alloy-logs.remoteConfig.secret.create     | bool   | `true`        | Whether to create a secret for the remote config server.                                 |
| alloy-logs.remoteConfig.secret.embed      | bool   | `false`       | If true, skip secret creation and embed the credentials directly into the configuration. |
| alloy-logs.remoteConfig.secret.name       | string | `""`          | The name of the secret to create.                                                        |
| alloy-logs.remoteConfig.secret.namespace  | string | `""`          | The namespace for the secret.                                                            |
| alloy-logs.remoteConfig.url               | string | `""`          | The URL of the remote config server.                                                     |

### Alloy Metrics

| Key                                          | Type   | Default         | Description                                                |
|----------------------------------------------|--------|-----------------|------------------------------------------------------------|
| alloy-metrics.controller.replicas            | int    | `1`             | The number of replicas for the Alloy Metrics instance.     |
| alloy-metrics.controller.type                | string | `"statefulset"` | The type of controller to use for the Alloy Metrics        |
| instance.                                    |        |                 |                                                            |
| alloy-metrics.enabled                        | bool   | `false`         | Deploy the Alloy instance for collecting metrics.          |
| alloy-metrics.extraConfig                    | string | `""`            | Extra Alloy configuration to be added to the configuration |
| file.                                        |        |                 |                                                            |
| alloy-metrics.liveDebugging.enabled          | bool   | `false`         | Enable live debugging for the Alloy instance.              |
| alloy-metrics.logging.format                 | string | `"logfmt"`      | Format to use for writing Alloy log lines.                 |
| alloy-metrics.logging.level                  | string | `"info"`        | Level at which Alloy log lines should be written.          |
| alloy-metrics.remoteConfig.auth.password     | string | `""`            | The password to use for the remote config                  |
| server.                                      |        |                 |                                                            |
| alloy-metrics.remoteConfig.auth.passwordFrom | string | `""`            | Raw config for accessing the password.                     |
| alloy-metrics.remoteConfig.auth.passwordKey  | string | `"password"`    | The key for storing the password in the                    |
| secret.                                      |        |                 |                                                            |
| alloy-metrics.remoteConfig.auth.type         | string | `"none"`        | The type of authentication to use for the remote           |
| config server.                               |        |                 |                                                            |
| alloy-metrics.remoteConfig.auth.username     | string | `""`            | The username to use for the remote config                  |
| server.                                      |        |                 |                                                            |
| alloy-metrics.remoteConfig.auth.usernameFrom | string | `""`            | Raw config for accessing the password.                     |
| alloy-metrics.remoteConfig.auth.usernameKey  | string | `"username"`    | The key for storing the username in the                    |
| secret.                                      |        |                 |                                                            |
| alloy-metrics.remoteConfig.enabled           | bool   | `false`         | Enable fetching configuration from a remote config         |
| server.                                      |        |                 |                                                            |
| alloy-metrics.remoteConfig.extraAttributes   | object | `{}`            | Attributes to be added to this collector when              |
| requesting configuration.                    |        |                 |                                                            |
| alloy-metrics.remoteConfig.pollFrequency     | string | `"5m"`          | The frequency at which to poll the remote config           |
| server for updates.                          |        |                 |                                                            |
| alloy-metrics.remoteConfig.proxyURL          | string | `""`            | The proxy URL to use of the remote config server.          |
| alloy-metrics.remoteConfig.secret.create     | bool   | `true`          | Whether to create a secret for the remote config           |
| server.                                      |        |                 |                                                            |
| alloy-metrics.remoteConfig.secret.embed      | bool   | `false`         | If true, skip secret creation and embed the                |
| credentials directly into the configuration. |        |                 |                                                            |
| alloy-metrics.remoteConfig.secret.name       | string | `""`            | The name of the secret to create.                          |
| alloy-metrics.remoteConfig.secret.namespace  | string | `""`            | The namespace for the secret.                              |
| alloy-metrics.remoteConfig.url               | string | `""`            | The URL of the remote config server.                       |

### Alloy Profiles

| Key                                           | Type   | Default       | Description                                                                              |
|-----------------------------------------------|--------|---------------|------------------------------------------------------------------------------------------|
| alloy-profiles.controller.type                | string | `"daemonset"` | The type of controller to use for the Alloy Profiles instance.                           |
| alloy-profiles.enabled                        | bool   | `false`       | Deploy the Alloy instance for gathering profiles.                                        |
| alloy-profiles.extraConfig                    | string | `""`          | Extra Alloy configuration to be added to the configuration file.                         |
| alloy-profiles.liveDebugging.enabled          | bool   | `false`       | Enable live debugging for the Alloy instance.                                            |
| alloy-profiles.logging.format                 | string | `"logfmt"`    | Format to use for writing Alloy log lines.                                               |
| alloy-profiles.logging.level                  | string | `"info"`      | Level at which Alloy log lines should be written.                                        |
| alloy-profiles.remoteConfig.auth.password     | string | `""`          | The password to use for the remote config server.                                        |
| alloy-profiles.remoteConfig.auth.passwordFrom | string | `""`          | Raw config for accessing the password.                                                   |
| alloy-profiles.remoteConfig.auth.passwordKey  | string | `"password"`  | The key for storing the password in the secret.                                          |
| alloy-profiles.remoteConfig.auth.type         | string | `"none"`      | The type of authentication to use for the remote config server.                          |
| alloy-profiles.remoteConfig.auth.username     | string | `""`          | The username to use for the remote config server.                                        |
| alloy-profiles.remoteConfig.auth.usernameFrom | string | `""`          | Raw config for accessing the username.                                                   |
| alloy-profiles.remoteConfig.auth.usernameKey  | string | `"username"`  | The key for storing the username in the secret.                                          |
| alloy-profiles.remoteConfig.enabled           | bool   | `false`       | Enable fetching configuration from a remote config server.                               |
| alloy-profiles.remoteConfig.extraAttributes   | object | `{}`          | Attributes to be added to this collector when requesting configuration.                  |
| alloy-profiles.remoteConfig.pollFrequency     | string | `"5m"`        | The frequency at which to poll the remote config server for updates.                     |
| alloy-profiles.remoteConfig.proxyURL          | string | `""`          | The proxy URL to use of the remote config server.                                        |
| alloy-profiles.remoteConfig.secret.create     | bool   | `true`        | Whether to create a secret for the remote config server.                                 |
| alloy-profiles.remoteConfig.secret.embed      | bool   | `false`       | If true, skip secret creation and embed the credentials directly into the configuration. |
| alloy-profiles.remoteConfig.secret.name       | string | `""`          | The name of the secret to create.                                                        |
| alloy-profiles.remoteConfig.secret.namespace  | string | `""`          | The namespace for the secret.                                                            |
| alloy-profiles.remoteConfig.url               | string | `""`          | The URL of the remote config server.                                                     |

### Alloy Receiver

| Key                                           | Type   | Default       | Description                                                                                                                                                                 |
|-----------------------------------------------|--------|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| alloy-receiver.alloy.extraPorts               | list   | `[]`          | The ports to expose for the Alloy receiver.                                                                                                                                 |
| alloy-receiver.controller.type                | string | `"daemonset"` | The type of controller to use for the Alloy Receiver instance.                                                                                                              |
| alloy-receiver.enabled                        | bool   | `false`       | Deploy the Alloy instance for opening receivers to collect application data.                                                                                                |
| alloy-receiver.extraConfig                    | string | `""`          | Extra Alloy configuration to be added to the configuration file.                                                                                                            |
| alloy-receiver.extraService.enabled           | bool   | `false`       | Create an extra service for the Alloy receiver. This service will mirror the alloy-receiver service, but its name can be customized to match existing application settings. |
| alloy-receiver.extraService.fullname          | string | `""`          | If set, the full name of the extra service to create. This will result in the format `<fullname>`.                                                                          |
| alloy-receiver.extraService.name              | string | `"alloy"`     | The name of the extra service to create. This will result in the format `<release-name>-<name>`.                                                                            |
| alloy-receiver.liveDebugging.enabled          | bool   | `false`       | Enable live debugging for the Alloy instance.                                                                                                                               |
| alloy-receiver.logging.format                 | string | `"logfmt"`    | Format to use for writing Alloy log lines.                                                                                                                                  |
| alloy-receiver.logging.level                  | string | `"info"`      | Level at which Alloy log lines should be written.                                                                                                                           |
| alloy-receiver.remoteConfig.auth.password     | string | `""`          | The password to use for the remote config server.                                                                                                                           |
| alloy-receiver.remoteConfig.auth.passwordFrom | string | `""`          | Raw config for accessing the password.                                                                                                                                      |
| alloy-receiver.remoteConfig.auth.passwordKey  | string | `"password"`  | The key for storing the password in the secret.                                                                                                                             |
| alloy-receiver.remoteConfig.auth.type         | string | `"none"`      | The type of authentication to use for the remote config server.                                                                                                             |
| alloy-receiver.remoteConfig.auth.username     | string | `""`          | The username to use for the remote config server.                                                                                                                           |
| alloy-receiver.remoteConfig.auth.usernameFrom | string | `""`          | Raw config for accessing the username.                                                                                                                                      |
| alloy-receiver.remoteConfig.auth.usernameKey  | string | `"username"`  | The key for storing the username in the secret.                                                                                                                             |
| alloy-receiver.remoteConfig.enabled           | bool   | `false`       | Enable fetching configuration from a remote config server.                                                                                                                  |
| alloy-receiver.remoteConfig.extraAttributes   | object | `{}`          | Attributes to be added to this collector when requesting configuration.                                                                                                     |
| alloy-receiver.remoteConfig.pollFrequency     | string | `"5m"`        | The frequency at which to poll the remote config server for updates.                                                                                                        |
| alloy-receiver.remoteConfig.proxyURL          | string | `""`          | The proxy URL to use of the remote config server.                                                                                                                           |
| alloy-receiver.remoteConfig.secret.create     | bool   | `true`        | Whether to create a secret for the remote config server.                                                                                                                    |
| alloy-receiver.remoteConfig.secret.embed      | bool   | `false`       | If true, skip secret creation and embed the credentials directly into the configuration.                                                                                    |
| alloy-receiver.remoteConfig.secret.name       | string | `""`          | The name of the secret to create.                                                                                                                                           |
| alloy-receiver.remoteConfig.secret.namespace  | string | `""`          | The namespace for the secret.                                                                                                                                               |
| alloy-receiver.remoteConfig.url               | string | `""`          | The URL of the remote config server.                                                                                                                                        |

### Alloy Singleton

| Key                                            | Type   | Default        | Description                                                                                                     |
|------------------------------------------------|--------|----------------|-----------------------------------------------------------------------------------------------------------------|
| alloy-singleton.controller.replicas            | int    | `1`            | The number of replicas for the Alloy Singleton instance. Must remain a single instance to avoid duplicate data. |
| alloy-singleton.controller.type                | string | `"deployment"` | The type of controller to use for the Alloy Singleton instance.                                                 |
| alloy-singleton.enabled                        | bool   | `false`        | Deploy the Alloy instance for data sources required to be deployed on a single replica.                         |
| alloy-singleton.extraConfig                    | string | `""`           | Extra Alloy configuration to be added to the configuration file.                                                |
| alloy-singleton.liveDebugging.enabled          | bool   | `false`        | Enable live debugging for the Alloy instance.                                                                   |
| alloy-singleton.logging.format                 | string | `"logfmt"`     | Format to use for writing Alloy log lines.                                                                      |
| alloy-singleton.logging.level                  | string | `"info"`       | Level at which Alloy log lines should be written.                                                               |
| alloy-singleton.remoteConfig.auth.password     | string | `""`           | The password to use for the remote config server.                                                               |
| alloy-singleton.remoteConfig.auth.passwordFrom | string | `""`           | Raw config for accessing the password.                                                                          |
| alloy-singleton.remoteConfig.auth.passwordKey  | string | `"password"`   | The key for storing the password in the secret.                                                                 |
| alloy-singleton.remoteConfig.auth.type         | string | `"none"`       | The type of authentication to use for the remote config server.                                                 |
| alloy-singleton.remoteConfig.auth.username     | string | `""`           | The username to use for the remote config server.                                                               |
| alloy-singleton.remoteConfig.auth.usernameFrom | string | `""`           | Raw config for accessing the username.                                                                          |
| alloy-singleton.remoteConfig.auth.usernameKey  | string | `"username"`   | The key for storing the username in the secret.                                                                 |
| alloy-singleton.remoteConfig.enabled           | bool   | `false`        | Enable fetching configuration from a remote config server.                                                      |
| alloy-singleton.remoteConfig.extraAttributes   | object | `{}`           | Attributes to be added to this collector when requesting configuration.                                         |
| alloy-singleton.remoteConfig.pollFrequency     | string | `"5m"`         | The frequency at which to poll the remote config server for updates.                                            |
| alloy-singleton.remoteConfig.proxyURL          | string | `""`           | The proxy URL to use of the remote config server.                                                               |
| alloy-singleton.remoteConfig.secret.create     | bool   | `true`         | Whether to create a secret for the remote config server.                                                        |
| alloy-singleton.remoteConfig.secret.embed      | bool   | `false`        | If true, skip secret creation and embed the credentials directly into the configuration.                        |
| alloy-singleton.remoteConfig.secret.name       | string | `""`           | The name of the secret to create.                                                                               |
| alloy-singleton.remoteConfig.secret.namespace  | string | `""`           | The namespace for the secret.                                                                                   |
| alloy-singleton.remoteConfig.url               | string | `""`           | The URL of the remote config server.                                                                            |
