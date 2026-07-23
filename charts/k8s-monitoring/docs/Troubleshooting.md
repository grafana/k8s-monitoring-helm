# Troubleshooting

Most of this content has moved to [Troubleshoot the Kubernetes Monitoring Helm chart configuration](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/troubleshooting/).

## Multiple Alloy Operators managing the same Alloy instances

This chart deploys the [Alloy Operator](https://github.com/grafana/alloy-operator), which reconciles the `Alloy`
custom resources (`collectors.grafana.com/v1alpha1`) this chart creates. Internally, the operator manages each `Alloy`
instance as its own Helm release.

If more than one Alloy Operator watches the same namespace, both operators try to manage the same `Alloy` instances and
their Helm releases. They continually overwrite each other's work, and the Helm release history is left in an
inconsistent state. An operator watches every namespace when it runs at **cluster scope** (no `WATCH_NAMESPACE`
restriction), and only its configured namespaces when it runs **namespace-scoped**
(`alloy-operator.ownNamespaceOnly: true` or `alloy-operator.namespaces`).

The chart detects this at install/upgrade time. If it finds another Alloy Operator that would compete with the bundled
one, it fails with guidance. See the `alloy-operator.conflictCheck` value to understand or disable the check.

### Symptoms

**Two cluster-scoped operators.** Because both operators watch every namespace, they both try to reconcile every `Alloy`
instance. The Alloy Pods are continually redeployed and restarted, and both operator Pods log a constant churn of
failing install/upgrade/rollback attempts, such as:

```text
"msg":"Release failed" ... "error":"upgrade failed; rollback required"
"msg":"Error rolling back release" ... "error":"rollback failed: release has no 0 version"
"error":"failed to install release: release: already exists"
"error":"failed to install release: cannot re-use a name that is still in use"
"error":"Operation cannot be fulfilled on alloys.collectors.grafana.com \"...\": the object has been modified; please apply your changes to the latest version and try again"
"error":"failed to install release: Unable to continue with install: ServiceAccount \"...\" ... exists and cannot be imported into the current release: invalid ownership metadata"
```

**One cluster-scoped operator and one namespace-scoped operator.** The two only overlap in the namespace the
namespace-scoped operator watches. The cluster-scoped operator "wins" that namespace, so the Alloy Pods stop being
restarted, but the losing operator keeps logging reconcile errors because the resources are already owned by the other
operator's releases:

```text
"error":"failed to install release: Unable to continue with install: ClusterRole \"...\" in namespace \"\" exists and cannot be imported into the current release: invalid ownership metadata"
"error":"Operation cannot be fulfilled on alloys.collectors.grafana.com \"...\": the object has been modified; please apply your changes to the latest version and try again"
"error":"failed to get candidate release: another operation (install/upgrade/rollback) is in progress"
```

### Resolution

Make sure only one Alloy Operator manages a given `Alloy` instance:

*   If your cluster already has an Alloy Operator, don't deploy the bundled one:

    ```yaml
    alloy-operator:
      deploy: false
    ```

    When `deploy` is `false`, this chart pins the Alloy image tag on its Alloy instances so the existing operator
    doesn't substitute its own, possibly older, default Alloy image. Set `image.tag` on a collector to override.

*   Otherwise, scope the operators so they don't overlap. Restrict this chart's operator to its own namespace:

    ```yaml
    alloy-operator:
      ownNamespaceOnly: true
    ```

    or to an explicit, non-overlapping set of namespaces:

    ```yaml
    alloy-operator:
      namespaces:
        - my-namespace
    ```

Two operators that are each namespace-scoped to different namespaces do not conflict.
