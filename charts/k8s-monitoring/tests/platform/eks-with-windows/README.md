<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# EKS with Windows nodes

This cluster runs both Linux and Windows nodes, with Node Exporter and Windows Exporter gathering host metrics from
each. Because the EKS control plane is managed by AWS, kube-scheduler and kube-controller-manager have no discoverable
Pods to scrape. Instead, their metrics are read from the
[EKS Control Plane Metrics API](https://docs.aws.amazon.com/eks/latest/userguide/view-control-plane-metrics.html) using
the `eks-proxy` discovery mode. This requires Kubernetes 1.28+ and an extra RBAC rule granting read access to the
`metrics.eks.amazonaws.com` API group, which is added to the collector's cluster rules.

Pod logs from the Windows nodes are gathered via the Kubernetes API, since a Windows Alloy pod cannot read host log
files the way a Linux pod can.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: eks-with-windows-test

destinations:
  grafana-cloud-metrics:
    type: prometheus
    url: https://prometheus-prod-13-prod-us-east-0.grafana.net/api/prom/push
    auth:
      type: basic
      usernameKey: PROMETHEUS_USER
      passwordKey: PROMETHEUS_PASS
    secret:
      create: false
      name: grafana-cloud-credentials
      namespace: default
  grafana-cloud-logs:
    type: loki
    url: https://logs-prod-006.grafana.net/loki/api/v1/push
    auth:
      type: basic
      usernameKey: LOKI_USER
      passwordKey: LOKI_PASS
    secret:
      create: false
      name: grafana-cloud-credentials
      namespace: default

dataProcessors:
  # Copies the EC2 instance `Team` tag onto telemetry, matching each node's `node` label to
  # its instance private DNS name via discovery.ec2.
  ec2-tags:
    type: ec2Enrichment
    region: ap-northeast-2
    tags:
      team: Team

clusterMetrics:
  enabled: true
  dataProcessors: [ec2-tags]

  # On EKS the control plane is managed by AWS, so kube-scheduler and kube-controller-manager have no
  # discoverable Pods. Scrape them from the EKS Control Plane Metrics API instead. This requires
  # Kubernetes 1.28+ and the metrics.eks.amazonaws.com RBAC rule added to the alloy collector below.
  controlPlane:
    enabled: true
  kubeScheduler:
    discoveryMode: eks-proxy
  kubeControllerManager:
    discoveryMode: eks-proxy

hostMetrics:
  enabled: true
  linuxHosts:
    enabled: true
  windowsHosts:
    enabled: true

clusterEvents:
  enabled: true
  clustering: true
  collector: alloy

nodeLogs:
  enabled: true
  collector: alloy

podLogsViaLoki:
  enabled: true

podLogsViaKubernetesApi:
  enabled: true
  nodeSelector:
    kubernetes.io/os: windows

integrations:
  alloy:
    instances:
      - name: alloy
        labelSelectors:
          app.kubernetes.io/name: [alloy]

collectors:
  alloy:
    presets: [clustered, filesystem-log-reader, daemonset]
    alloy:
      stabilityLevel: experimental  # Required for prometheus.enrich (ec2Enrichment processor)
    rbac:
      # The chart's default cluster-scoped RBAC rules, plus a rule granting read access to the EKS
      # Control Plane Metrics API so the `eks-proxy` discoveryMode can scrape kube-scheduler and
      # kube-controller-manager. Overriding clusterRules replaces the list, so the defaults are repeated here.
      clusterRules:
        - apiGroups: [""]
          resources: [nodes]
          verbs: [get, list, watch]
        - apiGroups: [""]
          resources: [nodes/pods]
          verbs: [get, list, watch]
        - apiGroups: [""]
          resources: [nodes/metrics]
          verbs: [get, list, watch]
        - nonResourceURLs: [/metrics]
          verbs: [get]
        # EKS Control Plane Metrics API (metrics.eks.amazonaws.com)
        - apiGroups: [metrics.eks.amazonaws.com]
          resources: [ksh/metrics, ksh/resourcemetrics, kcm/metrics]
          verbs: [get]

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true
  windows-exporter:
    deploy: true
```
<!-- textlint-enable terminology -->
