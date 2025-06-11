# Troubleshooting
<!--alex disable invalid-->

This document contains some information about frequently encountered issues and how to resolve them.

-   [General Tips](#general-tips)
    -   [Alloy Web UI](#alloy-web-ui)
-   [Instructions for specific Cluster platform providers](#instructions-for-specific-cluster-platform-providers)
-   [Frequently seen problems](#frequently-seen-problems)
    -   [Authentication error: invalid scope requested](#authentication-error-invalid-scope-requested)
    -   [Kepler pods crashing on AWS Graviton nodes](#kepler-pods-crashing-on-aws-graviton-nodes)
    -   [ResourceExhausted Error when Sending Traces](#resourceexhausted-error-when-sending-traces)

## General tips

### Alloy Web UI

Grafana Alloy has a
[web user interface](https://grafana.com/docs/alloy/latest/tasks/debug/#alloy-ui) that shows every configuration
component that the Alloy instance is using and the component status. By default, the web UI runs on each Alloy pod on port
`12345`. Since that UI is typically not exposed external to the Cluster, you can use port-forwarding to access it.

`kubectl port-forward svc/grafana-k8s-monitoring-alloy 12345:12345`

Then open a browser to `http://localhost:12345`

## Instructions for specific Cluster platform providers

Certain Kubernetes Cluster platforms require some specific configurations for this Helm chart. If your Cluster is
running on one of these platforms, see the example for the changes required to run this Helm chart:

-   [Azure AKS](examples/platforms/azure-aks)
-   [AWS EKS on Fargate](examples/platforms/eks-fargate)
-   [Google GKE Autopilot](examples/platforms/gke-autopilot)
-   [OpenShift](examples/platforms/openshift)

## Frequently seen problems

### Authentication error: invalid scope requested

To deliver telemetry data to Grafana Cloud, you use
an [Access Policy Token](https://grafana.com/docs/grafana-cloud/account-management/authentication-and-permissions/access-policies/)
with the appropriate scopes. Scopes define an action that can be done to a specific data type. For
example `metrics:write` permits writing metrics.

If sending data to Grafana Cloud, this Helm chart uses the `<data>:write` scopes for delivering data. It can optionally
use the `<data>:read` scopes when running the [Data Test Job](./HelmTests.md#data-test).

If your token does not have the correct scope, you will see errors in the Grafanaa Alloy logs. For example, when trying
to deliver profiles to Pyroscrope without the `profiles:write` scope:

```text
msg="final error sending to profiles to endpoint" component=pyroscope.write.profiles_service endpoint=https://tempo-prod-1-prod-eu-west-2.grafana.net:443 err="unauthenticated: authentication error: invalid scope requested"
```

The table below shows the scopes required for various actions done by this chart:

| Data type             | Server                                      | Scope for writing | Scope for reading |
|-----------------------|---------------------------------------------|-------------------|-------------------|
| Metrics               | Grafana Cloud Metrics (Prometheus or Mimir) | `metrics:write`   | `metrics:read`    |
| Logs & Cluster Events | Grafana Cloud Logs (Loki)                   | `logs:write`      | `logs:read`       |
| Traces                | Grafana Cloud Trace (Tempo)                 | `traces:write`    | `traces:read`     |
| Profiles              | Grafana Cloud Profiles (Pyroscope)          | `profiles:write`  | `profiles:read`   |

### Kepler pods crashing on AWS Graviton nodes

Kepler [cannot run](https://github.com/sustainable-computing-io/kepler/issues/1556) on AWS Graviton nodes and pods on
those nodes will CrashLoopBackOff. To prevent this, you can add a node selector to the Kepler deployment:

```yaml
kepler:
  nodeSelector:
    kubernetes.io/arch: amd64
```

### ResourceExhausted Error when Sending Traces

If you have traces enabled, and you see log entries in your `alloy` instance that looks like this:

```text
Permanent error: rpc error: code = ResourceExhausted desc = grpc: received message after decompression larger than max (5268750 vs. 4194304)" dropped_items=11226
ts=2024-09-19T19:52:35.16668052Z level=info msg="rejoining peers" service=cluster peers_count=1 peers=6436336134343433.grafana-k8s-monitoring-alloy-cluster.default.svc.cluster.local.:12345
```

It's likely due to the span size being too large. You can fix this by adjusting the batch size:

```yaml
receivers:
  processors:
    batch:
      maxSize: 2000
```

Start with 2000 and adjust as needed.
