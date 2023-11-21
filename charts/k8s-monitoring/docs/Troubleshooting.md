# Troubleshooting

## CustomResourceDefinition conflicts

The Kubernetes Monitoring chart deploys the [Prometheus Operator custom resource definitions](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-operator-crds) by default.

If those CRDs already exist on your cluster, you may see an error message like this when attempting to install:

```
Error: INSTALLATION FAILED: Unable to continue with install: CustomResourceDefinition "alertmanagerconfigs.monitoring.coreos.com" in namespace "" exists and cannot be imported into the current release: ..."
```

To fix this problem, you can either:
1. Remove the CRDs and let this chart deploy them
2. Disable the deployment of the CRDs in this chart by adding this to the values file:

    ```yaml
    prometheus-operator-crds:
      enabled: false
    ```
