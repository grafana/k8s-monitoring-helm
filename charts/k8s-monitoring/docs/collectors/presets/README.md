# Collector Presets

Presets are a way to set predefined configurations for Alloy collectors.

## Current presets

| Preset | Description |
|--------|-------------|
| [clustered](clustered.md) | Enables Alloy clustering to distribute telemetry gathering compatible work across multiple replicas. |
| [daemonset](daemonset.md) | Configures Alloy to run as a DaemonSet, ensuring a single instance per node. |
| [deployment](deployment.md) | Configures Alloy to run as a Deployment, with a default of 1 replica. |
| [filesystem-log-reader](filesystem-log-reader.md) | Configures Alloy to mount the /var/log from the Node's file system. |
| [privileged](privileged.md) | Configures Alloy to run with elevated privileges, allowing it to access system resources and perform operations that require root access. |
| [singleton](singleton.md) | Configures Alloy to run as a single-instance, protecting workloads that would result in duplicated data if run on multiple replicas. |
| [statefulset](statefulset.md) | Configures Alloy to run as a StatefulSet, with a default of 1 replica. |
