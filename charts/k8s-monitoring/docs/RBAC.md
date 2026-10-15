# RBAC

Each collector needs Kubernetes RBAC permissions to discover targets and read the objects its configuration uses. The
`rbac.mode` setting on each collector chooses who creates them.

| Mode               | Who creates the RBAC                     | What it grants                                                            |
|--------------------|------------------------------------------|---------------------------------------------------------------------------|
| `alloy` (default)  | The Alloy Operator, using the Alloy chart | The same broad ClusterRole for every collector                            |
| `minimal`          | This chart                               | Only what the collector's configuration needs, scoped to namespaces where possible |

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

In `minimal` mode, the chart knows which destinations run on each collector, and it scans user-supplied configuration,
so it renders only the rules they need:

*   Rules are put in Roles when the configuration limits a component to some namespaces, and in a ClusterRole
    otherwise.
*   A destination whose credentials are in a Kubernetes Secret gets `get` on that one Secret, in its namespace.
*   The ClusterRole and Roles show up in `helm template` output, so they can be reviewed.

The objects are named `<collector full name>-rbac`. Roles outside the release namespace, such as the one for a
destination's Secret in another namespace, are named `<collector full name>-<release namespace>-rbac`, so releases with
the same name in different namespaces don't collide. They are bound to the collector's ServiceAccount, which the Alloy
Operator still creates. The `Alloy` resource gets `rbac.create: false`, so the operator doesn't create its own RBAC.

Roles are created in the namespaces that the configuration names, so those namespaces must exist before you install the
chart. `--create-namespace` only creates the release namespace.

## What collectors are granted

The rules come from the bundles in
[collectors/rbac-bundles.yaml](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/collectors/rbac-bundles.yaml):

*   **A destination with credentials in a Kubernetes Secret**: `get` on that Secret, in its namespace.
*   **The SDK Injector**: `get`, `create`, and `update` on ConfigMaps in the release namespace, for the collectors listed
    in `telemetryServices.sdkInjector.allowedConfigMapWriters`.

### User-supplied configuration

The chart can't know what `extraConfig`, `replaceComponent`, custom destinations, and custom data processors do, so it
scans them for the components listed in
[collectors/alloy-kubernetes-api.yaml](https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/collectors/alloy-kubernetes-api.yaml),
and grants what those components need:

*   A component limited to namespaces listed as string literals, such as `namespaces { names = ["team-a"] }` in
    `discovery.kubernetes`, gets Roles in those namespaces. Otherwise, it gets a ClusterRole.
*   `remote.kubernetes.secret` and `remote.kubernetes.configmap` get `get` on the object they name. If the `namespace`
    isn't a string literal, that name is readable in every namespace. If the `name` isn't a string literal, every
    object in the namespace is readable. Use string literals to keep this access small.
*   Only the replaced components and custom data processor blocks that a collector renders are scanned.

The `k8s.grafana.com/rbac-user-config` annotation on the ClusterRole and Roles lists what was added.

The chart also scans the final configuration. If a component that uses the Kubernetes API isn't covered by the rules
above, it's granted what it needs and listed in the `k8s.grafana.com/rbac-inferred` annotation on the ClusterRole and
Roles. That annotation means the chart's rules are missing something, so please
[open an issue](https://github.com/grafana/k8s-monitoring-helm/issues) if you see it.

## Other RBAC settings

In minimal mode, `rbac.rules`, `rbac.clusterRules`, and `rbac.namespaces` aren't supported yet, and setting them fails
validation. They still work as before with `rbac.mode: alloy`. To create no RBAC at all for a collector, set
`rbac.create: false`.

## Remote configuration

Collectors with `remoteConfig.enabled` must use `alloy` mode. Remote configuration can run any component, so the chart
can't compute the rules it needs, and setting `rbac.mode: minimal` on such a collector fails validation.

## Switching modes

Helm creates RBAC objects before custom resources, so switching a collector from `alloy` to `minimal` creates the new
ClusterRole and Roles before the Alloy Operator removes its own. Permissions add up, so the collector keeps working
during the switch.

Switching from `minimal` back to `alloy` removes the chart's RBAC objects right away, but the Alloy Operator only
recreates its own when it reconciles the `Alloy` resource. The collector may lack permissions for a short time.

## The Alloy Operator's permissions

The Alloy Operator creates the RBAC objects for collectors in `alloy` mode, so it needs permission to create Roles and
ClusterRoles, including the `bind` and `escalate` verbs. It keeps those permissions while any collector uses `alloy`
mode, including collectors with remote configuration.
