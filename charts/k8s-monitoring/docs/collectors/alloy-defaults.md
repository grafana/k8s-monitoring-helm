# alloy-defaults

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy.clustering.enabled | bool | `false` | Deploy Alloy in a cluster to allow for load distribution. |
| alloy.clustering.name | string | `""` | Name for the Alloy cluster. Used for differentiating between clusters. |
| alloy.clustering.portName | string | `"http"` | Name for the port used for clustering, useful if running inside an Istio Mesh |
| alloy.configMap.content | string | `""` | Content to assign to the new ConfigMap.  This is passed into `tpl` allowing for templating from values. |
| alloy.configMap.create | bool | `true` | Create a new ConfigMap for the config file. |
| alloy.configMap.key | string | `nil` | Key in ConfigMap to get config from. |
| alloy.configMap.name | string | `nil` | Name of existing ConfigMap to use. Used when create is false. |
| alloy.enableReporting | bool | `true` | Enables sending Grafana Labs anonymous usage stats to help improve Grafana Alloy. |
| alloy.envFrom | list | `[]` | Maps all the keys on a ConfigMap or Secret as environment variables. https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#envfromsource-v1-core |
| alloy.extraArgs | list | `[]` | Extra args to pass to `alloy run`: https://grafana.com/docs/alloy/latest/reference/cli/run/ |
| alloy.extraEnv | list | `[]` | Extra environment variables to pass to the Alloy container. |
| alloy.extraPorts | list | `[]` | Extra ports to expose on the Alloy container. |
| alloy.hostAliases | list | `[]` | Host aliases to add to the Alloy container. |
| alloy.lifecycle | object | `{}` | Set lifecycle hooks for the Grafana Alloy container. |
| alloy.listenAddr | string | `"0.0.0.0"` | Address to listen for traffic on. 0.0.0.0 exposes the UI to other containers. |
| alloy.listenPort | int | `12345` | Port to listen for traffic on. |
| alloy.listenScheme | string | `"HTTP"` | Scheme is needed for readiness probes. If enabling tls in your configs, set to "HTTPS" |
| alloy.livenessProbe | object | `{}` | Set livenessProbe for the Grafana Alloy container. |
| alloy.mounts.dockercontainers | bool | `false` | Mount /var/lib/docker/containers from the host into the container for log collection. |
| alloy.mounts.extra | list | `[]` | Extra volume mounts to add into the Grafana Alloy container. Does not affect the watch container. |
| alloy.mounts.varlog | bool | `false` | Mount /var/log from the host into the container for log collection. |
| alloy.resources | object | `{}` | Resource requests and limits to apply to the Grafana Alloy container. |
| alloy.securityContext | object | `{}` | Security context to apply to the Grafana Alloy container. |
| alloy.stabilityLevel | string | `"generally-available"` | Minimum stability level of components and behavior to enable. Must be one of "experimental", "public-preview", or "generally-available". |
| alloy.storagePath | string | `"/tmp/alloy"` | Path to where Grafana Alloy stores data (for example, the Write-Ahead Log). By default, data is lost between reboots. |
| alloy.uiPathPrefix | string | `"/"` | Base path where the UI is exposed. |
| configReloader.customArgs | list | `[]` | Override the args passed to the container. |
| configReloader.enabled | bool | `true` | Enables automatically reloading when the Alloy config changes. |
| configReloader.image.digest | string | `""` | SHA256 digest of image to use for config reloading (either in format "sha256:XYZ" or "XYZ"). When set, will override `configReloader.image.tag` |
| configReloader.image.registry | string | `"ghcr.io"` | Config reloader image registry (defaults to docker.io) |
| configReloader.image.repository | string | `"jimmidyson/configmap-reload"` | Repository to get config reloader image from. |
| configReloader.image.tag | string | `"v0.14.0"` | Tag of image to use for config reloading. |
| configReloader.resources | object | `{"requests":{"cpu":"1m","memory":"5Mi"}}` | Resource requests and limits to apply to the config reloader container. |
| configReloader.securityContext | object | `{}` | Security context to apply to the Grafana configReloader container. |
| controller.affinity | object | `{}` | Affinity configuration for pods. |
| controller.autoscaling.enabled | bool | `false` | Creates a HorizontalPodAutoscaler for controller type deployment. |
| controller.autoscaling.maxReplicas | int | `5` | The upper limit for the number of replicas to which the autoscaler can scale up. |
| controller.autoscaling.minReplicas | int | `1` | The lower limit for the number of replicas to which the autoscaler can scale down. |
| controller.autoscaling.scaleDown.policies | list | `[]` | List of policies to determine the scale-down behavior. |
| controller.autoscaling.scaleDown.selectPolicy | string | `"Max"` | Determines which of the provided scaling-down policies to apply if multiple are specified. |
| controller.autoscaling.scaleDown.stabilizationWindowSeconds | int | `300` | The duration that the autoscaling mechanism should look back on to make decisions about scaling down. |
| controller.autoscaling.scaleUp.policies | list | `[]` | List of policies to determine the scale-up behavior. |
| controller.autoscaling.scaleUp.selectPolicy | string | `"Max"` | Determines which of the provided scaling-up policies to apply if multiple are specified. |
| controller.autoscaling.scaleUp.stabilizationWindowSeconds | int | `0` | The duration that the autoscaling mechanism should look back on to make decisions about scaling up. |
| controller.autoscaling.targetCPUUtilizationPercentage | int | `0` | Average CPU utilization across all relevant pods, a percentage of the requested value of the resource for the pods. Setting `targetCPUUtilizationPercentage` to 0 will disable CPU scaling. |
| controller.autoscaling.targetMemoryUtilizationPercentage | int | `80` | Average Memory utilization across all relevant pods, a percentage of the requested value of the resource for the pods. Setting `targetMemoryUtilizationPercentage` to 0 will disable Memory scaling. |
| controller.dnsPolicy | string | `"ClusterFirst"` | Configures the DNS policy for the pod. https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy |
| controller.enableStatefulSetAutoDeletePVC | bool | `false` | Whether to enable automatic deletion of stale PVCs due to a scale down operation, when controller.type is 'statefulset'. |
| controller.extraAnnotations | object | `{}` | Annotations to add to controller. |
| controller.extraContainers | list | `[]` | Additional containers to run alongside the Alloy container and initContainers. |
| controller.hostNetwork | bool | `false` | Configures Pods to use the host network. When set to true, the ports that will be used must be specified. |
| controller.hostPID | bool | `false` | Configures Pods to use the host PID namespace. |
| controller.initContainers | list | `[]` |  |
| controller.nodeSelector | object | `{}` | nodeSelector to apply to Grafana Alloy pods. |
| controller.parallelRollout | bool | `true` | Whether to deploy pods in parallel. Only used when controller.type is 'statefulset'. |
| controller.podAnnotations | object | `{}` | Extra pod annotations to add. |
| controller.podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":null,"minAvailable":null}` | PodDisruptionBudget configuration. |
| controller.podDisruptionBudget.enabled | bool | `false` | Whether to create a PodDisruptionBudget for the controller. |
| controller.podDisruptionBudget.maxUnavailable | string | `nil` | Maximum number of pods that can be unavailable during a disruption. Note: Only one of minAvailable or maxUnavailable should be set. |
| controller.podDisruptionBudget.minAvailable | string | `nil` | Minimum number of pods that must be available during a disruption. Note: Only one of minAvailable or maxUnavailable should be set. |
| controller.podLabels | object | `{}` | Extra pod labels to add. |
| controller.priorityClassName | string | `""` | priorityClassName to apply to Grafana Alloy pods. |
| controller.replicas | int | `1` | Number of pods to deploy. Ignored when controller.type is 'daemonset'. |
| controller.terminationGracePeriodSeconds | string | `nil` | Termination grace period in seconds for the Grafana Alloy pods. The default value used by Kubernetes if unspecifed is 30 seconds. |
| controller.tolerations | list | `[]` | Tolerations to apply to Grafana Alloy pods. |
| controller.topologySpreadConstraints | list | `[]` | Topology Spread Constraints to apply to Grafana Alloy pods. |
| controller.type | string | `"daemonset"` | Type of controller to use for deploying Grafana Alloy in the cluster. Must be one of 'daemonset', 'deployment', or 'statefulset'. |
| controller.updateStrategy | object | `{}` | Update strategy for updating deployed Pods. |
| controller.volumeClaimTemplates | list | `[]` | volumeClaimTemplates to add when controller.type is 'statefulset'. |
| controller.volumes.extra | list | `[]` | Extra volumes to add to the Grafana Alloy pod. |
| crds.create | bool | `true` | Whether to install CRDs for monitoring. |
| extraObjects | list | `[]` | Extra k8s manifests to deploy |
| fullnameOverride | string | `nil` | Overrides the chart's computed fullname. Used to change the full prefix of resource names. |
| global.image.pullSecrets | list | `[]` | Optional set of global image pull secrets. |
| global.image.registry | string | `""` | Global image registry to use if it needs to be overriden for some specific use cases (e.g local registries, custom images, ...) |
| global.podSecurityContext | object | `{}` | Security context to apply to the Grafana Alloy pod. |
| image.digest | string | `nil` | Grafana Alloy image's SHA256 digest (either in format "sha256:XYZ" or "XYZ"). When set, will override `image.tag`. |
| image.pullPolicy | string | `"IfNotPresent"` | Grafana Alloy image pull policy. |
| image.pullSecrets | list | `[]` | Optional set of image pull secrets. |
| image.registry | string | `"docker.io"` | Grafana Alloy image registry (defaults to docker.io) |
| image.repository | string | `"grafana/alloy"` | Grafana Alloy image repository. |
| image.tag | string | `nil` | Grafana Alloy image tag. When empty, the Chart's appVersion is used. |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` | Enables ingress for Alloy (Faro port) |
| ingress.extraPaths | list | `[]` |  |
| ingress.faroPort | int | `12347` |  |
| ingress.hosts[0] | string | `"chart-example.local"` |  |
| ingress.labels | object | `{}` |  |
| ingress.path | string | `"/"` |  |
| ingress.pathType | string | `"Prefix"` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `nil` | Overrides the chart's name. Used to change the infix in the resource names. |
| namespaceOverride | string | `nil` | Overrides the chart's namespace. |
| rbac.create | bool | `true` | Whether to create RBAC resources for Alloy. |
| service.annotations | object | `{}` |  |
| service.clusterIP | string | `""` | Cluster IP, can be set to None, empty "" or an IP address |
| service.enabled | bool | `true` | Creates a Service for the controller's pods. |
| service.internalTrafficPolicy | string | `"Cluster"` | Value for internal traffic policy. 'Cluster' or 'Local' |
| service.nodePort | int | `31128` | NodePort port. Only takes effect when `service.type: NodePort` |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount.additionalLabels | object | `{}` | Additional labels to add to the created service account. |
| serviceAccount.annotations | object | `{}` | Annotations to add to the created service account. |
| serviceAccount.automountServiceAccountToken | bool | `true` |  |
| serviceAccount.create | bool | `true` | Whether to create a service account for the Grafana Alloy deployment. |
| serviceAccount.name | string | `nil` | The name of the existing service account to use when serviceAccount.create is false. |
| serviceMonitor.additionalLabels | object | `{}` | Additional labels for the service monitor. |
| serviceMonitor.enabled | bool | `false` |  |
| serviceMonitor.interval | string | `""` | Scrape interval. If not set, the Prometheus default scrape interval is used. |
| serviceMonitor.metricRelabelings | list | `[]` | MetricRelabelConfigs to apply to samples after scraping, but before ingestion. ref: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#relabelconfig |
| serviceMonitor.relabelings | list | `[]` | RelabelConfigs to apply to samples before scraping ref: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#relabelconfig |
| serviceMonitor.tlsConfig | object | `{}` | Customize tls parameters for the service monitor |
