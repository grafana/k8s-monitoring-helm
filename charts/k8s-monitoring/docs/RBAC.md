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

The SDK Injector's ConfigMap writes come from values: `get`, `create`, and `update` on ConfigMaps in the release
namespace, for the collectors listed in `telemetryServices.sdkInjector.allowedConfigMapWriters`.

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
