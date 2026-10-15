# RBAC

Each collector needs Kubernetes RBAC permissions to discover targets and read the objects its configuration uses. The
`rbac.mode` setting on each collector chooses who creates them.

| Mode               | Who creates the RBAC                     | What it grants                                                            |
|--------------------|------------------------------------------|---------------------------------------------------------------------------|
| `alloy` (default)  | The Alloy Operator, using the Alloy chart | The same broad ClusterRole for every collector                            |
| `minimal`          | This chart                               | Only what the collector's configuration needs, scoped to namespaces where possible |

`minimal` is experimental, so how it works can change in later releases.

To use minimal RBAC for every collector, set it once:

```yaml
collectorCommon:
  alloy:
    rbac:
      mode: minimal
```

Or set it on a single collector:

```yaml
collectors:
  alloy-metrics:
    rbac:
      mode: minimal
```

## Why minimal mode exists

In `alloy` mode, every collector gets the Alloy chart's default ClusterRole, whatever it runs. That includes cluster-wide
read access to every Secret and ConfigMap. The RBAC is created by the Alloy Operator at runtime, so it doesn't appear in
`helm template` output.

In `minimal` mode, the chart reads each collector's final Alloy configuration and grants only what its components need:

*   Rules go in Roles when the configuration limits a component to namespaces written as string literals, and in a
    ClusterRole otherwise.
*   A component that reads one Secret or ConfigMap, such as the one with a destination's credentials, gets `get` on
    that object only.
*   The ClusterRole and Roles show up in `helm template` output, so they can be reviewed.

The ClusterRole, its binding, and Roles outside the release namespace, such as the one for a destination's Secret in
another namespace, are named `<collector full name>-<release namespace>-rbac`, so releases with the same name in
different namespaces don't collide. Roles in the release namespace are named `<collector full name>-rbac`. They are
bound to the collector's ServiceAccount, which the Alloy Operator still creates. The `Alloy` resource gets
`rbac.create: false`, so the operator doesn't create its own RBAC.

Roles are created in the namespaces that the configuration names, so those namespaces must exist before you install the
chart. `--create-namespace` only creates the release namespace.

## How the rules are computed

The chart scans each collector's final configuration, including `extraConfig`, `replaceComponent`, custom destinations,
and custom data processors, for the components listed in
[collectors/alloy-kubernetes-api.yaml](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/collectors/alloy-kubernetes-api.yaml).
That file maps each component to the bundles it needs, and
[collectors/rbac-bundles.yaml](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/collectors/rbac-bundles.yaml)
defines each bundle as RBAC rules.

*   `discovery.kubernetes` gets the resources for its `role`, in the namespaces from its `namespaces` block. A `role`
    that isn't a string literal gets every role's resources, cluster-wide. Setting `node` or `namespace` in its
    `attach_metadata` block to any value also grants read access to Nodes or Namespaces.
*   A component in a module (`declare`) that gets its namespaces from a module argument, like the integrations do, gets
    the namespaces that the module's callers pass, including callers in nested modules.
*   `loki.source.kubernetes` gets Pods and `get` on `pods/log` in the namespaces its targets are discovered in.
*   `otelcol.processor.k8sattributes` gets Pods, in the namespace of its `filter` block's `namespace`, or cluster-wide
    without one. It also gets Namespaces when a `label` or `annotation` reads from `namespace`, the `kube-system`
    Namespace for `k8s.cluster.uid`, and Nodes for `k8s.node.uid` or `from = "node"`. Workload objects (ReplicaSets,
    Deployments, StatefulSets, DaemonSets, Jobs, and CronJobs) follow the same namespace as Pods, only when its
    metadata or labels need them. With `passthrough = true`, it gets nothing.
*   `remote.kubernetes.secret` and `remote.kubernetes.configmap` get `get` on the object they name. If the `namespace`
    isn't a string literal, that name is readable in every namespace. If the `name` isn't a string literal, every
    object in the namespace is readable. Use string literals to keep this access small.
*   The Prometheus Operator components get their object type, and `get` on Secrets and ConfigMaps for credentials, in
    their `namespaces`. Without `namespaces`, that's every Secret and ConfigMap in the cluster. Their target discovery
    and Nodes are cluster-wide, because a monitor's `namespaceSelector` and `attachMetadata` are only known at runtime.
*   Rule and alert sync is cluster-wide. `mimir.rules.kubernetes`, which a Prometheus destination's `rules` settings
    render, and `loki.rules.kubernetes` get PrometheusRules and Namespaces. `mimir.alerts.kubernetes` gets
    AlertmanagerConfigs and Namespaces, and `get` on every Secret and ConfigMap for the credentials they reference. The
    chart doesn't render `loki.rules.kubernetes` or `mimir.alerts.kubernetes`, so they only come from your own
    configuration, such as `extraConfig`.
*   A scrape that sends the collector's ServiceAccount token gets what its targets check, based on where its targets
    come from: `get` on `nodes/metrics` for the kubelet, `get` on `nodes/proxy` through the API server's Node proxy
    (cluster metrics with `nodeAddressFormat: proxy`), the EKS Control Plane Metrics API (`discoveryMode: eks-proxy`),
    and `get` on `/metrics` for anything else, such as the API server. Scrapes at other paths only get `/metrics`, so
    they can fail with `forbidden` errors.
*   A `pyroscope.scrape` that sends the ServiceAccount token gets nothing extra, because it can only scrape targets from
    Pod, Service, Endpoints, or EndpointSlice discovery. A profiling endpoint behind a proxy that checks the token, such
    as kube-rbac-proxy, fails with `forbidden` errors.
*   Annotation autodiscovery sends the ServiceAccount token by default, so its collector gets `get` on `/metrics`. Set
    `annotationAutodiscovery.bearerToken.enabled: false` to remove it.

The SDK Injector's ConfigMap writes don't appear in the configuration, so they come from values instead: `get`, `create`,
and `update` on ConfigMaps in the release namespace, for the collectors listed in
`telemetryServices.sdkInjector.allowedConfigMapWriters`.

To see what each example is granted, see its file in
[tests/example-checks/rbac-minimal](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/tests/example-checks/rbac-minimal).

## Configuration that minimal mode fails on

The render fails, and says to use `rbac.mode: alloy` for that collector, when:

*   `remoteConfig.enabled` is set. Remote configuration can run any component, so the chart can't compute its rules.
*   `alloy.configMap` sets `name`, or `create: true`. The collector then runs a configuration that the chart doesn't
    build.
*   `rbac.rules`, `rbac.clusterRules`, or `rbac.namespaces` is set. These aren't supported in minimal mode yet. They
    still work as before with `rbac.mode: alloy`.
*   The collector doesn't create a ServiceAccount or name one.
*   `image.tag` is set to a different Alloy version than the one this chart uses by default, or `image.digest` is set.
    Minimal mode's rules are only verified against the default version, so it can't guarantee correct RBAC for another
    one. Variants of the default version, like the Windows image that the `windows` preset sets, are allowed.
*   A component block can't be read, for example because of unbalanced braces.
*   A scrape that sends the ServiceAccount token gets its targets from somewhere the chart can't follow, like a module
    argument, or a `pyroscope.scrape` sends it to targets that don't come from Pod, Service, Endpoints, or EndpointSlice
    discovery, like static targets or `discovery.kubelet`.

If minimal mode fails on configuration that it should support, please
[open an issue](https://github.com/grafana/k8s-monitoring-helm/issues).

## Other RBAC settings

To create no RBAC objects for a collector, set `rbac.create: false`. In `alloy` mode, the SDK Injector's ConfigMap Role
from `sdk-injector-rbac.yaml` still renders when the SDK Injector is deployed.

## Switching modes

Helm creates RBAC objects before custom resources, so switching a collector from `alloy` to `minimal` creates the new
ClusterRole and Roles before the Alloy Operator removes its own. Permissions add up, so the collector keeps working
during the switch.

Switching from `minimal` back to `alloy` removes the chart's RBAC objects right away, but the Alloy Operator only
recreates its own when it reconciles the `Alloy` resource. The collector may lack permissions for a short time.

When the SDK Injector is deployed, `alloy` mode lets every enabled collector write ConfigMaps in the release namespace.
`minimal` mode only lets the collectors listed in `telemetryServices.sdkInjector.allowedConfigMapWriters` write them, so
a collector that isn't listed loses that permission when it switches to `minimal`.

## The Alloy Operator's permissions

The Alloy Operator creates the RBAC objects for collectors in `alloy` mode, so it needs permission to create Roles and
ClusterRoles, including the `bind` and `escalate` verbs. It keeps those permissions while any collector uses `alloy`
mode, including collectors with remote configuration.
