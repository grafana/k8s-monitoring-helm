<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# RBAC: Custom rules

By default, every Alloy collector gets the same broad ClusterRole, which can read every Secret and ConfigMap in the
cluster. The permissions are this wide because of remote configuration. Fleet Management can send a collector a new
configuration at any time, and the chart can't know which components that configuration will use, so the defaults
cover all of them.

This example shows you how to reduce those permissions to only what each collector needs. You write the rules
yourself, in one of two ways. Both work the same with remote configuration, as long as your rules cover the components
in the configuration you send.

Option 1 is less YAML. Use Option 2 if a collector reads Secrets, because it's the only way to limit that access to one
namespace.

## Option 1: Replace the default rules

Set `rbac.rules` and `rbac.clusterRules` on the collector. These lists replace the defaults. They don't add to them. The
Alloy Operator still creates the ClusterRole and ClusterRoleBinding. The `alloy-metrics` collector in this example uses
this option.

This option has two limitations:

*   Both lists need at least one rule. If either one is empty, the Alloy chart fails to render the ClusterRole, so the
    Alloy Operator can't create it.
*   All the rules go into one ClusterRole, so they apply in every namespace. You can't grant some rules cluster-wide and
    others in a single namespace. If you set `rbac.namespaces`, the Alloy chart creates a Role in each of those
    namespaces instead, and drops `rbac.clusterRules` entirely.

## Option 2: Bring your own RBAC

Set `rbac.create: false` on the collector, and the Alloy Operator creates no RBAC objects for it. Then create your own
ClusterRoles, Roles, and bindings, with `extraObjects` as this example does or outside the chart. The `alloy-singleton`
and `alloy-logs` collectors in this example use this option.

You can scope each rule however you like. Here, those two collectors can read one Secret, the Loki destination's
credentials, and only in the release namespace. Because the objects come from this chart, `helm template` prints them,
and you can review them before you deploy.

Bind the rules to the collector's ServiceAccount. The Alloy Operator still creates it and names it
`<release name>-<collector name>`. If the release name already contains the collector name, the ServiceAccount is named
after the release. To use a ServiceAccount you create yourself, set `serviceAccount.create: false` and
`serviceAccount.name` on the collector.

## Which permissions a collector needs

The permissions depend on which Alloy components are in the collector's configuration:

| Component                                            | Resources                                                 | Verbs       | Scope                       |
|------------------------------------------------------|-----------------------------------------------------------|-------------|-----------------------------|
| `discovery.kubernetes` with `role = "node"`          | `nodes`                                                   | list, watch | Cluster                     |
| `discovery.kubernetes` with `role = "pod"`           | `pods`                                                    | list, watch | The namespaces it discovers |
| `discovery.kubernetes` with `role = "endpoints"`     | `endpoints`, `pods`, `services`                           | list, watch | The namespaces it discovers |
| `discovery.kubernetes` with `role = "endpointslice"` | `endpointslices` (`discovery.k8s.io`), `pods`, `services` | list, watch | The namespaces it discovers |
| `prometheus.scrape` of the Kubelet or cAdvisor       | `nodes/metrics`                                           | get         | Cluster                     |
| `loki.source.kubernetes_events`                      | `events`                                                  | list, watch | The namespaces it watches   |
| `remote.kubernetes.secret`                           | `secrets`, limited with `resourceNames`                   | get         | The Secret's namespace      |
| `remote.kubernetes.configmap`                        | `configmaps`, limited with `resourceNames`                | get         | The ConfigMap's namespace   |

The `rbac` section of the [Alloy chart values](../../../collectors/upstream/alloy-values.yaml) lists every default rule
and the component that needs it.

To see which components a collector runs, read its `.alloy` file next to this example, or its ConfigMap on the cluster.

A missing permission shows up as an error from the component that needs it, such as
`failed to list *v1.Pod: pods is forbidden`. After you deploy, check the collector's logs or the Alloy UI.

## Other RBAC in this chart

This example only changes the Alloy collectors' RBAC. These components have their own RBAC settings:

*   kube-state-metrics, Node Exporter, and the other telemetry services: `telemetryServices.<service>.rbac`
*   The Alloy Operator: `alloy-operator.rbac`

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: rbac-custom

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
  loki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: 1
    auth:
      type: basic
      username: loki
      password: lokipassword
    secret:
      name: loki-credentials

clusterMetrics:
  enabled: true
  collector: alloy-metrics

hostMetrics:
  enabled: true
  collector: alloy-metrics
  linuxHosts:
    enabled: true

clusterEvents:
  enabled: true
  collector: alloy-singleton

podLogsViaLoki:
  enabled: true
  collector: alloy-logs

collectors:
  # Option 1: Replace the default rules. The Alloy Operator still creates the RBAC objects.
  alloy-metrics:
    presets: [clustered, statefulset]
    rbac:
      # Discover kube-state-metrics and Node Exporter. Both lists must be non-empty.
      rules:
        - apiGroups: [""]
          resources: [endpoints, pods, services]
          verbs: [list, watch]
      # Discover Nodes and scrape the Kubelet and cAdvisor.
      clusterRules:
        - apiGroups: [""]
          resources: [nodes]
          verbs: [list, watch]
        - apiGroups: [""]
          resources: [nodes/metrics]
          verbs: [get]

  # Option 2: Bring your own RBAC. The RBAC objects are defined in extraObjects below.
  alloy-singleton:
    presets: [singleton]
    rbac:
      create: false
  alloy-logs:
    presets: [filesystem-log-reader, daemonset]
    rbac:
      create: false

telemetryServices:
  kube-state-metrics:
    deploy: true
  node-exporter:
    deploy: true

extraObjects:
  # alloy-singleton: watch Kubernetes events in all namespaces.
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: "{{ .Release.Name }}-alloy-singleton"
    rules:
      - apiGroups: [""]
        resources: [events]
        verbs: [list, watch]
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: "{{ .Release.Name }}-alloy-singleton"
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: "{{ .Release.Name }}-alloy-singleton"
    subjects:
      - kind: ServiceAccount
        name: "{{ .Release.Name }}-alloy-singleton"
        namespace: "{{ .Release.Namespace }}"

  # alloy-logs: discover Pods in all namespaces.
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: "{{ .Release.Name }}-alloy-logs"
    rules:
      - apiGroups: [""]
        resources: [pods]
        verbs: [list, watch]
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: "{{ .Release.Name }}-alloy-logs"
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: "{{ .Release.Name }}-alloy-logs"
    subjects:
      - kind: ServiceAccount
        name: "{{ .Release.Name }}-alloy-logs"
        namespace: "{{ .Release.Namespace }}"

  # alloy-singleton and alloy-logs: read only the Loki destination's Secret.
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: "{{ .Release.Name }}-loki-credentials-reader"
      namespace: "{{ .Release.Namespace }}"
    rules:
      - apiGroups: [""]
        resources: [secrets]
        resourceNames: [loki-credentials]
        verbs: [get]
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: "{{ .Release.Name }}-loki-credentials-reader"
      namespace: "{{ .Release.Namespace }}"
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: "{{ .Release.Name }}-loki-credentials-reader"
    subjects:
      - kind: ServiceAccount
        name: "{{ .Release.Name }}-alloy-singleton"
        namespace: "{{ .Release.Namespace }}"
      - kind: ServiceAccount
        name: "{{ .Release.Name }}-alloy-logs"
        namespace: "{{ .Release.Namespace }}"
```
<!-- textlint-enable terminology -->
