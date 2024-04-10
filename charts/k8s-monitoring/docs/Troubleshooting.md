# Troubleshooting

This document contains some information about frequently encountered issues and how to resolve them.

* [Instructions for specific Cluster platform providers](#instructions-for-specific-cluster-platform-providers)
* [CustomResourceDefinition conflicts](#customresourcedefinition-conflicts)
* [Pod log files in /var/lib/docker/containers](#pod-log-files-in-varlibdockercontainers)
* [Authentication error: invalid scope requested](#authentication-error-invalid-scope-requested)

## Instructions for specific Cluster platform providers

Certain Kubernetes Cluster platforms require some specific configurations for this Helm chart. If your Cluster is
running on one of these platforms, see the example for the changes required to run this Helm chart:

* [AWS EKS on Fargate](../../../examples/eks-fargate)
* [Google GKE Autopilot](../../../examples/gke-autopilot)
* [IBM Cloud](../../../examples/ibm-cloud)
* [OpenShift](../../../examples/openshift-compatible)

## CustomResourceDefinition conflicts

The Kubernetes Monitoring chart deploys
the [Prometheus Operator custom resource definitions](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-operator-crds)
by default.

If those CRDs already exist on your cluster, you may see an error message like this when attempting to install:

```text
Error: INSTALLATION FAILED: Unable to continue with install: CustomResourceDefinition "alertmanagerconfigs.monitoring.coreos.com" in namespace "" exists and cannot be imported into the current release: ..."
```

To fix this problem, you can either:

1. Remove the CRDs and let this chart deploy them.
2. Disable the deployment of the CRDs in this chart by adding this to the values file:

    ```yaml
    prometheus-operator-crds:
      enabled: false
    ```

## Pod log files in `/var/lib/docker/containers`

On certain Kubernetes Clusters, Pod logs are stored inside of `/var/lib/docker/containers` with `/var/log/pods` being
symlinked to that directory, but the Grafana Agent doesn't mount it by default.
If your Cluster works this way, you'll likely see errors in the Grafana Agent for Logs pods like this:

```text
ts=2023-12-26T20:23:33.462127486Z level=error msg="error getting os stat" component=local.file_match.pod_logs path=/var/log/pods/prod_simulation-assignment-797d7f7d85-hdnfn_ce3f8946-0fe9-44c4-9ffb-7f28b51ce39f/simulation-assignment-service/0.log err="stat /var/log/pods/prod_simulation-assignment-797d7f7d85-hdnfn_ce3f8946-0fe9-44c4-9ffb-7f28b51ce39f/simulation-assignment-service/0.log: no such file or directory"
```

If this is the case, add this to your values file and re-deploy:

```yaml
grafana-agent-logs:
  agent:
    mounts:
      dockercontainers: true
```

([source](https://github.com/grafana/k8s-monitoring-helm/issues/309))

## Authentication error: invalid scope requested

To deliver telemetry data to Grafana Cloud, you use
an [Access Policy Token](https://grafana.com/docs/grafana-cloud/account-management/authentication-and-permissions/access-policies/)
with the appropriate scopes. Scopes define an action that can be done to a specific data type. For
example `metrics:write` permits writing metrics.

If sending data to Grafana Cloud, this Helm chart uses the `<data>:write` scopes for delivering data. It can optionally
use the `<data>:read` scopes when running the [Data Test Job](./HelmTests.md#data-test).

If your token does not have the correct scope, you will see errors in the Grafanaa Agent logs. For example, when trying
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
