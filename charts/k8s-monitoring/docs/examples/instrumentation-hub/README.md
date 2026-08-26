<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Example: instrumentation-hub/values.yaml

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: instrumentation-hub-test-cluster

collectorCommon:
  alloy:
    remoteConfig:
      enabled: true
      url: https://fleet-management-prod-008.grafana.net
      auth:
        type: basic
        usernameKey: GRAFANA_CLOUD_FLEET_MGMT_USER
        passwordKey: GRAFANA_CLOUD_FLEET_MGMT_TOKEN
      secret:
        create: false
        name: grafana-cloud-credentials

collectors:
  alloy-daemonset:
    presets: [xlarge, root, host-network, host-storage, host-cgroup, host-tracefs, clustered, service-discovery, filesystem-log-reader, daemonset]
    controller:
      autoscaling:
        vertical:
          enabled: true
          resourcePolicy:
            containerPolicies:
              - containerName: alloy
                controlledResources: [cpu, memory]
                controlledValues: RequestsAndLimits
                maxAllowed:
                  cpu: 4
                  memory: 8Gi
                minAllowed:
                  cpu: 1
                  memory: 2Gi

  alloy-deployment:
    presets: [xlarge, clustered, otel-receiver, deployment]
    extraService:
      enabled: true
      name: otel-receiver
    controller:
      autoscaling:
        horizontal:
          enabled: true
          minReplicas: 1
          maxReplicas: 5
          targetCPUUtilizationPercentage: 75
          targetMemoryUtilizationPercentage: 80

telemetryServices:
  node-exporter:
    deploy: true

  kube-state-metrics:
    deploy: true

  beyla:
    deploy: true
    k8sCache:
      replicas: 1

  sdkInjector:
    deploy: true
    # This must match the format: system:serviceaccount:$(POD_NAMESPACE):${ReleaseName}-${CollectorName}
    allowedConfigMapWriters: system:serviceaccount:$(POD_NAMESPACE):k8smon-alloy-daemonset,system:serviceaccount:$(POD_NAMESPACE):k8smon-alloy-deployment
```
<!-- textlint-enable terminology -->
