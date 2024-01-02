# Troubleshooting

## CustomResourceDefinition conflicts

The Kubernetes Monitoring chart deploys the [Prometheus Operator custom resource definitions](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-operator-crds) by default.

If those CRDs already exist on your cluster, you may see an error message like this when attempting to install:

```text
Error: INSTALLATION FAILED: Unable to continue with install: CustomResourceDefinition "alertmanagerconfigs.monitoring.coreos.com" in namespace "" exists and cannot be imported into the current release: ..."
```

To fix this problem, you can either:
1. Remove the CRDs and let this chart deploy them
2. Disable the deployment of the CRDs in this chart by adding this to the values file:

    ```yaml
    prometheus-operator-crds:
      enabled: false
    ```

## Pod log files in `/var/lib/docker/containers`

On certain Kubernetes clusters, pod logs are stored inside of `/var/lib/docker/containers` with `/var/log/pods` being symlinked to that directory, but the Grafana Agent doesn't mount it by default.
If your cluster works this way, you'll likely see errors in the Grafana Agent for Logs pods like this:

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
