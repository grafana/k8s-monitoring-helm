# Troubleshooting

This document contains some information about frequently encountered issues and how to resolve them.

-   [General Tips](#general-tips)
    -   [Alloy Web UI](#alloy-web-ui)
-   [Instructions for specific Cluster platform providers](#instructions-for-specific-cluster-platform-providers)
-   [Frequently seen problems](#frequently-seen-problems)
    -   [CustomResourceDefinition conflicts](#customresourcedefinition-conflicts)
    -   [Pod log files in `/var/lib/docker/containers`](#pod-log-files-in-varlibdockercontainers)
    -   [Authentication error: invalid scope requested](#authentication-error-invalid-scope-requested)
    -   [Kepler pods crashing on AWS Graviton nodes](#kepler-pods-crashing-on-aws-graviton-nodes)
    -   [ConfigMaps show `\n` and not newlines](#configmaps-show-n-and-not-newlines)

## General tips

### Alloy Web UI

Grafana Alloy has a
[web user interface](https://grafana.com/docs/alloy/latest/tasks/debug/#alloy-ui) that shows every configuration
component that Alloy instance is using and their statuses. By default, the web UI runs on each Alloy pod on port
`12345`. Since that UI is typically not exposed external to the Cluster, you can use port-forwarding to access it.

`kubectl port-forward svc/grafana-k8s-monitoring-alloy 12345:12345`

Then open a browser to `http://localhost:12345`

## Instructions for specific Cluster platform providers

Certain Kubernetes Cluster platforms require some specific configurations for this Helm chart. If your Cluster is
running on one of these platforms, see the example for the changes required to run this Helm chart:

-   [Azure AKS](../../../examples/azure-aks)
-   [AWS EKS on Fargate](../../../examples/eks-fargate)
-   [Google GKE Autopilot](../../../examples/gke-autopilot)
-   [IBM Cloud](../../../examples/ibm-cloud)
-   [OpenShift](../../../examples/openshift-compatible)

## Frequently seen problems

### CustomResourceDefinition conflicts

The Kubernetes Monitoring chart deploys
the [Prometheus Operator custom resource definitions](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-operator-crds)
by default.

If those CRDs already exist on your cluster, you may see an error message like this when attempting to install:

```text
Error: INSTALLATION FAILED: Unable to continue with install: CustomResourceDefinition "alertmanagerconfigs.monitoring.coreos.com" in namespace "" exists and cannot be imported into the current release: ..."
```

To fix this problem, you can either:

1.  Remove the CRDs and let this chart deploy them.
2.  Disable the deployment of the CRDs in this chart by adding this to the values file:

    ```yaml
    prometheus-operator-crds:
      enabled: false
    ```

### Pod log files in `/var/lib/docker/containers`

On certain Kubernetes Clusters, Pod logs are stored inside of `/var/lib/docker/containers` with `/var/log/pods` being
symlinked to that directory, but the Grafana Alloy instance doesn't mount it by default.
If your Cluster works this way, you'll likely see errors in the Grafana Alloy for Logs pods like this:

```text
ts=2023-12-26T20:23:33.462127486Z level=error msg="error getting os stat" component=local.file_match.pod_logs path=/var/log/pods/prod_simulation-assignment-797d7f7d85-hdnfn_ce3f8946-0fe9-44c4-9ffb-7f28b51ce39f/simulation-assignment-service/0.log err="stat /var/log/pods/prod_simulation-assignment-797d7f7d85-hdnfn_ce3f8946-0fe9-44c4-9ffb-7f28b51ce39f/simulation-assignment-service/0.log: no such file or directory"
```

If this is the case, add this to your values file and re-deploy:

```yaml
alloy-logs:
  alloy:
    mounts:
      dockercontainers: true
```

([source](https://github.com/grafana/k8s-monitoring-helm/issues/309))

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
those nodes will crash. To prevent this, you can add a node selector to the Kepler deployment:

```yaml
kepler:
  nodeSelector:
    kubernetes.io/arch: amd64
```

### ConfigMaps show `\n` and not newlines

If you see `\n` in the ConfigMaps instead of newlines, it's likely due to extra newlines in the config file. See
[this issue](https://github.com/kubernetes/kubernetes/issues/36222) for details. An example:

```yaml
apiVersion: v1
data:
  config.alloy: "discovery.kubernetes \"nodes\" {\n  role = \"node\"\n}\n\ndiscovery.kubernetes
    \"services\" {\n  role = \"service\"\n}\n\ndiscovery.kubernetes \"endpoints\"
    {\n  role = \"endpoints\"\n}\n\ndiscovery.kubernetes \"pods\" {\n  role = \"pod\"\n}\n\n//
    OTLP Receivers\notelcol.receiver.otlp \"receiver\" {\n  grpc {\n    endpoint =
```

To fix this, ensure that any multi-line configuration blocks in your values file use `|-` instead of `|`. For example:

```yaml
metrics:
  kube-state-metrics:
    extraMetricRelabelingRules: |-     # Make sure to use |- here
      rule {...}
```
