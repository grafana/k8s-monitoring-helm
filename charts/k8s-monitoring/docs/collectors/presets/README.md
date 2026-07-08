# Collector Presets

Presets are a way to set predefined configurations for Alloy collectors.

## Current presets

| Preset | Description |
|--------|-------------|
| [clustered](clustered.md) | Enables Alloy clustering to distribute telemetry gathering compatible work across multiple replicas. |
| [daemonset](daemonset.md) | Configures Alloy to run as a DaemonSet, ensuring a single instance per node. |
| [deployment](deployment.md) | Configures Alloy to run as a Deployment, with a default of 1 replica. |
| [filesystem-log-reader](filesystem-log-reader.md) | Configures Alloy to mount the /var/log from the Node's file system. |
| [host-cgroup](host-cgroup.md) | Mounts the host's cgroup filesystem into Alloy, allowing it to read cgroup information for the node. |
| [host-network](host-network.md) | Runs Alloy in the host's PID and network namespaces, with a matching `dnsPolicy` so cluster DNS resolution keeps working. This lets Alloy observe host-level processes and networking, and is required for Beyla auto-instrumentation. |
| [host-storage](host-storage.md) | Persists Alloy's storage (Write-Ahead Log, positions files, etc.) to a hostPath volume. Using a hostPath for a DaemonSet avoids the issues that come with PersistentVolumeClaim management. |
| [large](large.md) | Sets resource requests and limits sized for large clusters (approximately up to 1000 nodes or heavy telemetry workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) for tuning. |
| [linux-host-monitor](linux-host-monitor.md) | Grants Alloy the privileges needed to collect Linux host metrics directly using `prometheus.exporter.unix`, without requiring a separate Node Exporter deployment. It mounts the host's root, proc, and sys filesystems, runs privileged, and exposes the node name as the `NODE_NAME` environment variable. Use with `hostMetrics.linuxHosts.source: alloy` and combine with the `daemonset` preset so Alloy runs on every node, e.g. `presets: [linux-host-monitor, daemonset]`. |
| [medium](medium.md) | Sets resource requests and limits sized for medium clusters (approximately up to 250 nodes or moderate telemetry workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) for tuning. |
| [privileged](privileged.md) | DEPRECATED: use the `root` preset for the privileged `securityContext` and the `host-network` preset for `hostPID`. Configures Alloy to run with elevated privileges, allowing it to access system resources and perform operations that require root access. This preset cannot be combined with the `root` or `host-network` presets. |
| [root](root.md) | Runs Alloy as a privileged root container by setting only the `securityContext` (privileged, root user and group, and allowed privilege escalation). Combine with the `host-network`, `host-storage`, and `host-cgroup` presets to grant the specific host access a collector needs. |
| [service-discovery](service-discovery.md) | Sets the "service-discovery" attribute when using remote configuration, which indicates that this collector instance should get cluster service discovery configuration. |
| [singleton](singleton.md) | Configures Alloy to run as a single-instance, protecting workloads that would result in duplicated data if run on multiple replicas. |
| [small](small.md) | Sets resource requests and limits sized for small clusters (approximately up to 50 nodes or light telemetry workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) for tuning. |
| [statefulset](statefulset.md) | Configures Alloy to run as a StatefulSet, with a default of 1 replica. |
| [xlarge](xlarge.md) | Sets resource requests and limits sized for very large clusters (approximately 1000+ nodes or heavy telemetry workloads). See [Alloy resource estimation guidelines](https://grafana.com/docs/alloy/latest/introduction/estimate-resource-usage/) for tuning. |

## Collector sizing

The following presets set resource requests and limits for Alloy collectors. Choose the size
that best matches your cluster size and telemetry workload.

| Size | CPU Request | Memory Request | CPU Limit | Memory Limit |
|------|-------------|----------------|-----------|--------------|
| [small](small.md) | 100m | 128Mi | 500m | 512Mi |
| [medium](medium.md) | 250m | 512Mi | 1000m | 1Gi |
| [large](large.md) | 500m | 1Gi | 2000m | 2Gi |
| [xlarge](xlarge.md) | 1000m | 2Gi | 4000m | 4Gi |
