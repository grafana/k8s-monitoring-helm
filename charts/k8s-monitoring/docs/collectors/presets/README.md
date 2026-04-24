# Collector Presets

Presets are a way to set predefined configurations for Alloy collectors.

## Current presets

| Preset | Description |
|--------|-------------|
| [clustered](clustered.md) | Enables Alloy clustering to distribute telemetry gathering compatible work across multiple replicas. |
| [daemonset](daemonset.md) | Configures Alloy to run as a DaemonSet, ensuring a single instance per node. |
| [deployment](deployment.md) | Configures Alloy to run as a Deployment, with a default of 1 replica. |
| [filesystem-log-reader](filesystem-log-reader.md) | Configures Alloy to mount the /var/log from the Node's file system. |
| [large](large.md) | Sets resource requests and limits sized for large clusters (approximately up to 1000 nodes or heavy telemetry workloads). |
| [medium](medium.md) | Sets resource requests and limits sized for medium clusters (approximately up to 250 nodes or moderate telemetry workloads). |
| [privileged](privileged.md) | Configures Alloy to run with elevated privileges, allowing it to access system resources and perform operations that require root access. |
| [singleton](singleton.md) | Configures Alloy to run as a single-instance, protecting workloads that would result in duplicated data if run on multiple replicas. |
| [small](small.md) | Sets resource requests and limits sized for small clusters (approximately up to 50 nodes or light telemetry workloads). |
| [statefulset](statefulset.md) | Configures Alloy to run as a StatefulSet, with a default of 1 replica. |
| [xlarge](xlarge.md) | Sets resource requests and limits sized for very large clusters (approximately 1000+ nodes or heavy telemetry workloads). |
