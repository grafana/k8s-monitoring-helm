<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# OpenShift

This test shows the modifications required to deploy to an
[OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift) cluster.

OpenShift already runs its own kube-state-metrics and Node Exporter in the `openshift-monitoring` namespace, so the
chart skips deploying its own and instead scrapes the existing components over HTTPS using the pod's service account
bearer token. Setting `global.platform: openshift` also generates the SecurityContextConstraints objects that grant
Alloy the permissions it needs.

The Alloy pods cannot enable `readOnlyRootFilesystem` because they need to write to their storage path, so this test
provisions a PersistentVolume for that path. The log-reading collector also runs with the `container_logreader_t`
SELinux type so it is allowed to read the container log files.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: openshift-test

global:
  platform: openshift

destinations:
  grafanaCloudMetrics:
    type: prometheus
    url: https://prometheus-prod-13-prod-us-east-0.grafana.net/api/prom/push
    auth:
      type: basic
      usernameKey: PROMETHEUS_USER
      passwordKey: PROMETHEUS_PASS
    secret:
      create: false
      name: grafana-cloud-credentials
  grafanaCloudLogs:
    type: loki
    url: https://logs-prod-006.grafana.net/loki/api/v1/push
    auth:
      type: basic
      usernameKey: LOKI_USER
      passwordKey: LOKI_PASS
    secret:
      create: false
      name: grafana-cloud-credentials

clusterMetrics:
  enabled: true
  collector: alloy-metrics
  kube-state-metrics:
    namespace: openshift-monitoring
    labelMatchers:
      app.kubernetes.io/name: kube-state-metrics
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    service:
      scheme: https
      portName: https-main

hostMetrics:
  enabled: true
  collector: alloy-metrics
  linuxHosts:
    enabled: true
    namespace: openshift-monitoring
    labelMatchers:
      app.kubernetes.io/name: node-exporter
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    scheme: https

clusterEvents:
  enabled: true
  collector: alloy-singleton

autoInstrumentation:
  enabled: true
  collector: alloy-metrics

podLogsViaLoki:
  enabled: true
  collector: alloy-logs

integrations:
  collector: alloy-metrics
  alloy:
    instances:
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: [alloy-metrics, alloy-singleton, alloy-logs]

collectors:
  alloy-metrics:
    presets: [clustered, statefulset]
    alloy:
      storagePath: /var/lib/alloy
      mounts:
        extra:
          - name: alloy-storage
            mountPath: /var/lib/alloy

    controller:
      enableStatefulSetAutoDeletePVC: true
      volumeClaimTemplates:
        - metadata:
            name: alloy-storage
          spec:
            accessModes: ["ReadWriteOnce"]
            storageClassName: "standard-csi"
            resources:
              requests:
                storage: 1Gi

  alloy-singleton:
    presets: [singleton]

  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
    global:
      podSecurityContext:
        seLinuxOptions:
          type: container_logreader_t
```
<!-- textlint-enable terminology -->
