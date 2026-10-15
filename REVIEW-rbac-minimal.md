# Minimal RBAC: notes for reviewers

This file is temporary. It explains how `rbac.mode: minimal` (#2732) is put together, for people reviewing the stack
below. The last branch deletes it, so it never ships. The user-facing docs are in `charts/k8s-monitoring/docs/RBAC.md`,
added in `2-mode` and extended by the branches after it.

## The stack

| #   | Branch                                    | Adds                                                                         |
|-----|-------------------------------------------|------------------------------------------------------------------------------|
| 0   | `rbac-minimal-v2/0-review-doc`            | This file                                                                    |
| 1   | `rbac-minimal-v2/1-refactor`              | Shared feature/destination lists and subchart namespace helpers. No output change. |
| 2   | `rbac-minimal-v2/2-mode`                  | `rbac.mode`, rendering, the validations of values, the SDK Injector rule     |
| 3   | `rbac-minimal-v2/3-scanner`               | The scanner and both catalogs, with `discovery.kubernetes`, `discovery.kubelet`, and `remote.kubernetes.*` |
| 4   | `rbac-minimal-v2/4-checks`                | Golden files, the upstream Alloy RBAC snapshot, the catalogs' Alloy version check |
| 5   | `rbac-minimal-v2/5-cluster-metrics`       | Scrapes that send the ServiceAccount token, the `nodes/proxy` NOTES warning  |
| 6   | `rbac-minimal-v2/6-metrics-features`      | The Prometheus Operator, rule and alert sync, and profiling components, the `forbidden` log check |
| 7   | `rbac-minimal-v2/7-logs-features`         | The logs components, k8sattributes, the `rbac-minimal` example               |
| 8   | `rbac-minimal-v2/8-app-o11y-destinations` | Resource detection, the load balancer, Beyla, and OAuth2                     |
| 9   | `rbac-minimal-v2/9-validations`           | Failing on what the catalog can't cover. Deletes this file.                  |

Each branch from 5 to 8 adds a group of catalog entries with their unit tests, and regenerates the golden files, so its
diff shows exactly what those entries grant in every example. Integration tests land in the first branch where
everything they exercise is granted.

The stack targets `release-4.6` and only ships as a whole.

## What minimal mode does

In `alloy` mode, the default, the Alloy Operator gives every collector the Alloy chart's broad ClusterRole. In `minimal`
mode, the chart sets `spec.rbac.create: false` on the `Alloy` resource and renders its own ClusterRole, Roles, and
bindings, named `<collector fullname>-rbac`, with only what that collector's config needs. It applies to collectors,
tail-sampling instances, and service-graph instances. Alloy mode output is unchanged.

## How a collector's RBAC is computed

The chart reads each collector's final Alloy config once and grants what the components in it need.

1.  **Scan.** `collectors.rbac.scan` finds every component listed in `collectors/alloy-kubernetes-api.yaml` and maps
    it to bundles in `collectors/rbac-bundles.yaml`. Namespaces written as string literals scope the bundles to Roles.
    Anything else is cluster-wide. A component in a module gets the namespaces that the module's callers pass, and a
    scrape that sends the ServiceAccount token is followed back to where its targets come from.
2.  **Values-only rules.** The SDK Injector ConfigMap writes don't appear in the config, so they come from
    `telemetryServices.sdkInjector.allowedConfigMapWriters`.
3.  **Rules.** Bundles expand into verbs per resource, per scope. Rules marked `clusterScoped: true`, and
    `nonResourceURLs`, always go to the ClusterRole. Rules a broader grant covers are dropped.
4.  **Render.** A ClusterRole and binding, and a Role and binding per namespace.

`alloy-config.yaml`, `alloy-sampler.yaml`, and `alloy-servicegraph.yaml` render the RBAC right after each instance,
because that's where the final config is built.

## The two catalogs

Both files are in `charts/k8s-monitoring/collectors/`. One describes Alloy, the other describes Kubernetes RBAC.

*   **`alloy-kubernetes-api.yaml`** lists the Alloy components that use the Kubernetes API. For each one it says which
    bundles the component needs and how to read its scope from the config: a `namespaces` block, a `namespaces`
    attribute, a k8sattributes `filter`, or a named object, like the Secret a `remote.kubernetes.secret` reads. Some
    entries depend on a setting, like `discovery.kubernetes`, whose bundles depend on `role`. This is the file to
    update when Alloy adds or changes a component.
*   **`rbac-bundles.yaml`** defines each bundle as Kubernetes RBAC rules: API groups, resources, verbs, and whether a
    rule is cluster-scoped. Bundles are shared, so `pods` is used by pod discovery, Beyla, and the Prometheus Operator
    components. This is the file to read to see exactly what gets granted.

For example, `discovery.kubernetes "pods" { role = "pod" }` maps to the `pods` bundle in `alloy-kubernetes-api.yaml`,
and `rbac-bundles.yaml` defines `pods` as `get`, `list`, and `watch` on Pods.

## Validation

Minimal mode never installs a collector that's missing permissions. Instead, the render fails and says to use
`rbac.mode: alloy` for that collector, when:

*   `remoteConfig.enabled` is set, because the config isn't known.
*   `rbac.rules`, `rbac.clusterRules`, or `rbac.namespaces` is set. These only work in alloy mode for now.
*   No ServiceAccount is created or named.
*   The scanner can't read a component block, for example because of unbalanced braces.
*   The config has an `import` block, which loads configuration the scanner can't see.
*   The config has a component whose name looks like it uses Kubernetes (`kubernetes`, `kubelet`, `k8s`) but isn't in
    the catalog.
*   A component authenticates with the ServiceAccount token
    (`/var/run/secrets/kubernetes.io/serviceaccount/token`) and no catalog entry covers it, like a kubelet scrape the
    catalog doesn't recognize.

## Keeping the catalogs current with Alloy

The two catalogs are the source of truth for every permission minimal mode grants. They were written by hand from the
Alloy source and docs for Alloy v1.20.0. These checks make sure an Alloy update can't silently leave them behind:

1.  **Verified version.** Each catalog records the Alloy version it was checked against. A misc check fails when the
    chart's pinned Alloy version changes and the catalogs still name the old one, so every Alloy bump includes a
    catalog review.
2.  **Upstream RBAC snapshot.** The build renders the default ClusterRole rules of the Alloy chart version that the
    Alloy Operator embeds into `collectors/upstream/alloy-rbac.yaml`, next to `alloy-values.yaml`. CI fails when they
    change. Alloy adds permissions there when a component needs new ones, so a change points at the components to
    recheck.
3.  **Unknown components.** The validation above fails on Kubernetes components the catalog doesn't know, so a new
    Alloy component can't run with missing permissions.
4.  **Runtime coverage.** Every catalog entry is exercised by a minimal-mode integration test, and the tests fail on
    `forbidden` errors in the Alloy logs. Alloy update PRs run them.

## Design decisions

*   **One scan of the final config.** The config is what Alloy runs, so it's the only complete source.
*   **RBAC renders next to each instance.** The scan needs the final config, which only those templates build. A
    separate template would build every collector's config twice.
*   **Catalogs are data files.** What gets granted is reviewable in two YAML files. `clusterScoped` is set per rule
    because some bundles mix namespaced and cluster-scoped resources.
*   **The scanner reads Alloy syntax with regular expressions.** It removes comments, masks braces in strings, handles
    8 levels of nested blocks, and only trusts string literals for namespaces and names. A `role` that isn't a literal
    gets every role's bundles, cluster-wide. It splits the config into `declare` scopes, so it can follow a module
    argument to the calls that pass it, and a scrape's `targets` back through `discovery.relabel` to their source.
*   **Role names.** Roles outside the release namespace are named `<fullname>-<release namespace>-rbac`, so two
    releases with the same name can share a Secret namespace. Roles need their namespaces to exist before install.
*   **SDK Injector.** Minimal mode grants ConfigMap writes only to collectors listed in `allowedConfigMapWriters`.
    Alloy mode keeps the existing shim in `sdk-injector-rbac.yaml`.

## Supporting a new component

1.  Add the component to `alloy-kubernetes-api.yaml`, with how to read its scope.
2.  Add any new bundles to `rbac-bundles.yaml`, and mark cluster-scoped rules.
3.  Add a unit test, and cover it in an integration test.
4.  Regenerate the golden files and review the RBAC diff.

## Testing

*   **Unit tests:** `tests/rbac_minimal_*_test.yaml`.
*   **Golden files:** every example's minimal-mode RBAC objects are committed in
    `tests/example-checks/rbac-minimal/<example>.yaml`. CI renders them again and fails on any difference, so every
    change to what gets granted shows up as a diff in review.
*   **Integration tests:** each suite in `tests/integration/rbac-minimal/` checks the expected RBAC objects exist, the
    operator's ClusterRole doesn't, data arrives, every scrape target is up, and Alloy logs no `forbidden` errors.

| Suite                         | Branch | Covers                                                                   |
|-------------------------------|--------|--------------------------------------------------------------------------|
| `prometheus-operator-objects` | 6      | Monitor namespaces as Roles, cluster-wide target discovery, attached Node metadata, an Ingress Probe, rule and alert sync |
| `logs`                        | 7      | Pod logs via the Kubernetes API and OpenTelemetry, PodLogs objects, Node labels |
| `namespaced`                  | 7      | Features limited to one namespace, with no ClusterRole                   |
| `upgrade`                     | 7      | Switching from alloy to minimal mode on a running release, token scrapes of the API server and through the Node proxy |
| `application-observability`   | 8      | k8sattributes with workload metadata and a namespace filter, the sampler and service graph load balancers, resource detection |
| `extra-config`                | 9      | `extraConfig`, `replaceComponent`, a Secret and a ConfigMap read by name, kubelet discovery, attached metadata, EndpointSlice and Ingress discovery |

Each suite also deploys a small Alloy that ships the collectors' own logs to Loki, so the `forbidden` check sees startup
errors too. EKS control plane metrics, and the `kubeadm` and `eks` resource detectors, aren't covered on kind.

## Known limitations

*   ClusterRole names don't include the release namespace, so two releases with the same name in different namespaces
    collide. Alloy mode has the same limitation.
*   Config the catalog can't account for fails validation, so those collectors have to use `rbac.mode: alloy`.
*   `discovery.kubelet` gets `nodes/pods`, which kubelets only accept with fine-grained kubelet authorization
    (Kubernetes 1.33 or later).
