# Draft Migration Guide: 3.x → 4.0

This working document captures everything we need to publish a proper 3.x → 4.0 migration path. Use it to coordinate
doc/UX updates and to keep track of unresolved questions before we send content to the official migration guide
maintainers. When referencing existing public docs, follow the structure used in [Migrate to another Helm chart
version].

> Reference: [Grafana Cloud - Migrate to another Helm chart version](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/helm-chart-config/helm-chart/migrate-helm-chart/) (covers 1.x/2.x/3.x today; we need to extend it for 4.0).

## Audience Checklist

- Source chart: Any 3.x release (3.0–3.8). Confirm current version with `helm list -n <ns>` or `helm status`.
- Target chart: 4.0.0-beta (first release that includes telemetry services split + collectors map).
- Upgrading users already rely on the v3 values file semantics described in the existing Grafana doc above.

## Major Breaking Changes To Document

| Category | Impact | User action |
|----------|--------|-------------|
| Telemetry service deployment | kube-state-metrics, Node Exporter, Windows Exporter, Kepler, and OpenCost move out of feature blocks and into a shared `telemetryServices` map. | Move every `*.deploy` flag into `telemetryServices.<workload>.deploy` and update the new feature blocks to reference `hostMetrics.*` / `clusterMetrics.kube-state-metrics` / `costMetrics.opencost`. |
| Collector definitions | Static collectors (`alloy-metrics`, `alloy-logs`, etc.) are being replaced by a `collectors` map later in 4.0. For the first telemetry-services milestone we still ship the v3 collectors, but the guide should warn users. | Describe interim guidance now and leave TODO for final collector-map syntax. |
| Values schema validation | Features now `fail` during template rendering if the paired telemetry service is neither deployed nor referenced via selectors. | Document exact error strings and how to fix them. |

## Telemetry Services Mapping (v3 → v4)

| Workload | v3 location | v4 location | Notes |
|----------|-------------|-------------|-------|
| kube-state-metrics | `clusterMetrics.kube-state-metrics.*` (including `deploy`) | `telemetryServices.kube-state-metrics.deploy` + `clusterMetrics.kube-state-metrics.*` | You must either set `deploy: true` or provide `namespace`/`labelMatchers`. |
| Node Exporter | `clusterMetrics.node-exporter.*` | `telemetryServices.node-exporter.deploy` + `hostMetrics.linuxHosts.*` | `linuxHosts.enabled` replaces the legacy `node-exporter.enabled`. |
| Windows Exporter | `clusterMetrics.windows-exporter.*` | `telemetryServices.windows-exporter.deploy` + `hostMetrics.windowsHosts.*` | Same validation rules as Linux hosts. |
| Kepler | `clusterMetrics.kepler.*` | `telemetryServices.kepler.deploy` + `hostMetrics.energyMetrics.*` | `energyMetrics.enabled` controls scraping. |
| OpenCost | `costMetrics.opencost.deploy` | `telemetryServices.opencost.deploy` + `costMetrics.opencost.*` | Destinations now referenced via `opencost.metricsSource`. |

TODO:
- Verify if any integrations/examples relied on the old `clusterMetrics.<svc>.deploy` flags (control-plane example, AKS platform sample, etc.).
- Add windows exporter + kepler examples once we render them with `make examples`.

## Step-by-step Migration Outline (draft for docs team)

1. **Back up your values:** capture `helm get values <release> -n <ns> > values-v3.yaml`.
2. **Identify telemetry workloads in use:** search `clusterMetrics`, `costMetrics.opencost`, `node-exporter`, `windows-exporter`, `kepler`. Decide per workload whether the Helm chart will deploy it or whether you point to an existing installation.
3. **Populate the `telemetryServices` map:** move every `*.deploy` flag here. Example:

   ```yaml
   telemetryServices:
     kube-state-metrics:
       deploy: true
     node-exporter:
       deploy: true
   ```

4. **Update feature sections:**
   - `clusterMetrics.kube-state-metrics` keeps scrape tuning but no longer owns deployment.
   - `hostMetrics.linuxHosts/windowsHosts/energyMetrics` replace the old node/window exporter blocks.
   - `costMetrics.opencost` expects `telemetryServices.opencost` plus the new `metricsSource` helper.
5. **Reference existing services (if applicable):** set `telemetryServices.<svc>.deploy: false` and add selectors:

   ```yaml
   hostMetrics:
     linuxHosts:
       enabled: true
       namespace: monitoring
       labelMatchers:
         app.kubernetes.io/name: prometheus-node-exporter
   ```

6. **Remote config deployments:** keep feature blocks disabled, only deploy telemetry services so Fleet Management can push config later. Reuse the example from `Splitting-feature-and-services.md`.
7. **Validate locally:** run `helm template` or `make examples` to catch validation failures. Copy the exact `fail` messages from `_validation.tpl` into this guide for troubleshooting.

## Example Before/After (values excerpt)

```yaml
# v3 style
clusterMetrics:
  enabled: true
  node-exporter:
    enabled: true
    deploy: true
  kube-state-metrics:
    enabled: true
    deploy: true

# v4 style
telemetryServices:
  node-exporter:
    deploy: true
  kube-state-metrics:
    deploy: true
hostMetrics:
  enabled: true
  linuxHosts:
    enabled: true
clusterMetrics:
  enabled: true
  kube-state-metrics:
    enabled: true
```

## Validation Messages To Quote (copy exact strings later)

- From `feature-host-metrics` `_validation.tpl` (linux/windows/energy errors).
- From `feature-cluster-metrics` `_validation.tpl` (kube-state-metrics error).
- From `feature-cost-metrics` `_validation.tpl` (OpenCost error).

## Open Questions / Follow-ups

1. Provide yq snippets that automate rewriting `clusterMetrics.node-exporter` blocks into the new structure.
2. Clarify when the collectors map lands and whether 4.0 GA requires both migrations simultaneously.
3. Sync wording/style with the existing published migration doc before handing it off to the docs team.
