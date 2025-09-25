# Repository Guidelines

## Project Structure & Module Organization
The root hosts shared tooling (`Makefile`, `scripts/`, linters), documentation, and repo config. Helm charts live under `charts/`: `charts/k8s-monitoring` (v3) and `charts/k8s-monitoring-v1` (v1). Each chart ships with its own `Makefile`, `templates/`, `values.yaml`, tests, and docs such as `charts/k8s-monitoring/docs/examples`. Treat README files, schemas, and rendered examples as build outputs; modify the sources and rerun the chart targets instead of editing generated files.

## k8s-monitoring Chart (v3) Overview
- Deploys Grafana Alloy–powered telemetry collection for Kubernetes clusters (metrics, logs, traces).
- Alloy instances run under the Alloy Operator, which manages the required Alloy custom resources.
- The main `values.yaml` exposes common settings; supporting catalogs expand the option set for collectors (`charts/k8s-monitoring/collectors/alloy-values.yaml`), destination types (`charts/k8s-monitoring/destinations/*-values.yaml`), and feature modules (`charts/k8s-monitoring/charts/feature-*/values.yaml`).
- Features are packaged as internal subcharts in `charts/k8s-monitoring/charts/feature-*`, keeping logic isolated so enabling telemetry is simply `featureX.enabled: true`.

## Build, Test, and Development Commands
- `make build`: Rebuilds every chart and regenerates documentation, schemas, and example manifests.
- `make test`: Runs repository-wide linting plus helm-unittest suites.
- `make lint`: Executes YAML, Markdown, shell, terraform, and GitHub Actions linters.
- `make -C charts/k8s-monitoring build` or `test`: Limits work to the v3 chart; run `make -C charts/k8s-monitoring update-test-snapshots` after intentional template updates.

## Coding Style & Naming Conventions
Indent YAML with two spaces. Keep `values.yaml` keys in `camelCase`; Helm templates use kebab-case filenames and place helpers in `templates/_*.tpl`. Markdown must satisfy `.markdownlint.yml` (incremental headings, language-tagged fences). Run `make lint` before committing to catch style regressions.

## Testing Guidelines
Unit coverage relies on `helm-unittest`; invoke via `make test` or `make -C charts/k8s-monitoring unittest`. Integration scenarios live in `charts/k8s-monitoring/tests/integration/` and run with `helm-test <path>`. Update expected snapshots with `make -C charts/k8s-monitoring update-test-snapshots` whenever template output changes.

## Commit & Pull Request Guidelines
Write commits in imperative present tense, adding chart scope when helpful (e.g., `k8s-monitoring: Update datasource defaults`). Pull requests must describe the change and rationale, link issues, and demonstrate that `make build` and `make test` pass. Regenerate and include `README.md`, `values.schema.json`, `Chart.lock`, and example outputs whenever dependencies, values, or feature modules change.

## Security & Configuration Tips
Verify Helm ≥ 3.14 locally; `make build` enforces the requirement. Run tooling locally for speed—Docker fallbacks in the Makefiles cover missing binaries. For cloud or integration tests, set environment variables such as `DELETE_CLUSTER=true` to manage resource cleanup.
