# Multi-deployment integration test

This test runs **two independent copies of the `k8s-monitoring` chart in a single
cluster**, one per namespace:

| Copy | Deployed as                          | Release      | Namespace       | `cluster.name`         | Alloy Operator        |
| ---- | ------------------------------------ | ------------ | --------------- | ---------------------- | --------------------- |
| One  | test dependency (Flux `HelmRelease`) | `k8smon-one` | `namespace-one` | `multi-deployment-one` | deployed (cluster-wide) |
| Two  | test subject (local chart)           | `k8smon-two` | `namespace-two` | `multi-deployment-two` | **not deployed**      |

Copy one uses the released chart and stands in for a k8s-monitoring instance that
is *already running* in the cluster. Copy two is the local chart under test.
Both copies ship metrics and logs to the same Prometheus and Loki, and because
each uses a distinct `cluster.name`, the test proves the two copies run
independently.

## Conflicts this test guards against

Running two copies of the chart in one cluster is **not** safe with the default
values. The following conflicts must be handled, and the values in `values.yaml`
and `dependencies/k8s-monitoring-namespace-one.yaml` show how:

1. **The Alloy Operator watches every namespace, so run only one.**
   By default the operator sets no `WATCH_NAMESPACE` and reconciles Alloy
   instances in *all* namespaces. Two copies would mean two cluster-wide
   operators, each trying to manage the *other* copy's Alloy instances — the two
   operators fight over the same resources. This test resolves that by deploying
   a **single** operator: copy two sets `alloy-operator.deploy: false`, and copy
   one's operator (which already watches every namespace) reconciles the Alloy
   instances for *both* copies. The `kubernetes-objects-test` asserts that copy
   two has no operator of its own yet its Alloy collectors are still created.

   > An alternative is to keep both operators but restrict each to its own
   > namespace with `alloy-operator.ownNamespaceOnly: true`. This test uses the
   > single shared-operator approach instead.

2. **Node-level DaemonSets bind host ports and cannot share one.**
   `node-exporter` runs with `hostNetwork: true` and binds port `9100` on every
   node, so a second copy's `node-exporter` cannot start next to the first. Copy
   two moves its `node-exporter` to port `9101`
   (`telemetryServices.node-exporter.service.port: 9101`), which also sets the
   container's `--web.listen-address`, so both DaemonSets run on the same nodes.

3. **Release names must be distinct.**
   All cluster-scoped resources the chart creates (e.g. `kube-state-metrics`
   `ClusterRole`/`ClusterRoleBinding`) are prefixed with the release name. The
   two copies therefore use different release names (`k8smon-one` vs
   `k8smon-two`); reusing a release name would collide on these cluster-scoped
   objects.

## Notes

- The Alloy CRD (`alloys.collectors.grafana.com`) is installed from the
  `alloy-operator` sub-chart's `crds/` directory. Copy one installs it (and runs
  the operator); copy two disables the operator sub-chart entirely, so it relies
  on the CRD and operator already provided by copy one. Because copy one is
  deployed first (as a dependency) and waited on before the subject, the CRD and
  operator are in place by the time copy two's Alloy instances are created.
