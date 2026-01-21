# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains Helm charts for Kubernetes monitoring using Grafana's observability stack. The primary charts are:

-   **k8s-monitoring** (v3.x) - Modern architecture using Grafana Alloy Operator with CRD-based collectors
-   **k8s-monitoring-v1** (v1.x) - Legacy chart with direct Alloy deployment via Helm dependencies

## Key Configuration Resources

When working on features or debugging issues, these are the primary configuration files users interact with. Always check these first to understand how the chart is configured and what options are available:

### Main Chart Configuration

-   `charts/k8s-monitoring/values.yaml` - Main chart configuration with all feature toggles
-   `charts/k8s-monitoring/README.md` - Generated documentation of all configuration options

### Feature Subcharts

Each feature has its own values.yaml and README.md:

-   `charts/k8s-monitoring/charts/feature-cluster-metrics/` - Kubernetes metrics collection
-   `charts/k8s-monitoring/charts/feature-pod-logs/` - Pod log collection
-   `charts/k8s-monitoring/charts/feature-node-logs/` - Node system logs
-   `charts/k8s-monitoring/charts/feature-cluster-events/` - Kubernetes events
-   `charts/k8s-monitoring/charts/feature-application-observability/` - OTLP traces/metrics
-   `charts/k8s-monitoring/charts/feature-integrations/` - Service integrations
-   `charts/k8s-monitoring/charts/feature-annotation-autodiscovery/` - Service discovery
-   `charts/k8s-monitoring/charts/feature-auto-instrumentation/` - Auto OTEL instrumentation
-   `charts/k8s-monitoring/charts/feature-profiling/` - Continuous profiling
-   `charts/k8s-monitoring/charts/feature-prometheus-operator-objects/` - PrometheusRule/ServiceMonitor

### Destinations

-   `charts/k8s-monitoring/destinations/prometheus-values.yaml` - Prometheus remote write defaults
-   `charts/k8s-monitoring/destinations/loki-values.yaml` - Loki destination defaults
-   `charts/k8s-monitoring/destinations/otlp-values.yaml` - OTLP destination defaults
-   `charts/k8s-monitoring/destinations/pyroscope-values.yaml` - Pyroscope destination defaults

### Integration-Specific Configuration

Located in `charts/k8s-monitoring/charts/feature-integrations/`:

-   `integrations/<service>-values.yaml` - Default configuration per integration
-   `docs/integrations/<service>.md` - Integration-specific documentation

### Documentation and Examples

-   `charts/k8s-monitoring/docs/` - Architecture, features, migration guides
-   `charts/k8s-monitoring/docs/examples/` - Complete configuration examples
-   `charts/k8s-monitoring/docs/destinations/` - Destination configuration guides

**Important**: When developing features or fixing bugs, test against realistic configuration scenarios from the examples directory. The examples represent common user configurations and are tested in CI.

**Note**: A separate `.cursor/rules/k8s-monitoring-helm-v2-usage.mdc` file exists to help SREs and platform engineers configure the chart. That's for end users; this CLAUDE.md is for developers.

## Commands

### Build

```bash
# Build all charts (generates README, schema, examples, docs)
make build

# Build specific chart
make -C charts/k8s-monitoring build

# Build only feature subcharts
make -C charts/k8s-monitoring build-features

# Clean generated files
make clean
```

### Testing

```bash
# Run all tests (unit + lint + checks)
make test

# Run unit tests only
make -C charts/k8s-monitoring unittest

# Update test snapshots
make -C charts/k8s-monitoring update-test-snapshots

# Run example checks
make -C charts/k8s-monitoring example-checks

# Run misc checks
make -C charts/k8s-monitoring misc-checks

# Run feature tests
make -C charts/k8s-monitoring test-features
```

### Linting

```bash
# Run all linters
make lint

# Lint Alloy configuration files
make lint-alloy

# Lint Helm charts
make -C charts/k8s-monitoring lint-helm

# Lint generated Alloy configs from examples
make -C charts/k8s-monitoring lint-configs

# Lint YAML files
make lint-yaml

# Lint shell scripts
make lint-shell

# Lint markdown files
make lint-markdown
```

### Integration Testing

```bash
# Run specific integration test (creates kind cluster)
helm-test charts/k8s-monitoring/tests/integration/<test-dir>

# Delete cluster after test
DELETE_CLUSTER=true helm-test charts/k8s-monitoring/tests/integration/<test-dir>
```

### Development Tools

```bash
# Install node dependencies for linters
make install

# Test with specific Helm version
scripts/helm-with-version 3.14.4 version
scripts/helm-with-version 3.14.4 template k8smon charts/k8s-monitoring -f values.yaml

# Update chart dependencies
helm dependency update charts/k8s-monitoring

# Update feature dependencies
rm charts/k8s-monitoring/Chart.lock
make -C charts/k8s-monitoring build
```

### Release

```bash
# Set new version (also updates app version)
./scripts/set-version.sh 1.2.3

# Set version with specific app version
./scripts/set-version.sh 1.2.3 3.1.2
```

## Architecture

### k8s-monitoring Chart (v3.x)

The modern architecture uses a feature-based design where features are independent Helm subcharts that generate Grafana Alloy configurations.

#### Key Concepts

**Collectors**: Separate Alloy instances deployed by Alloy Operator, each specialized for different telemetry types:

-   `alloy-metrics` - Cluster and service metrics
-   `alloy-logs` - Pod and node logs
-   `alloy-singleton` - Cluster-wide events and single-instance features
-   `alloy-receiver` - OTLP/Pyroscope receivers
-   `alloy-profiles` - Continuous profiling

**Features**: Modular subcharts in `charts/k8s-monitoring/charts/feature-*` that generate Alloy module configurations:

-   `feature-cluster-metrics` - Kubernetes metrics (kubelet, kube-state-metrics, node-exporter)
-   `feature-pod-logs` - Pod log collection
-   `feature-node-logs` - Node system logs
-   `feature-cluster-events` - Kubernetes events
-   `feature-application-observability` - OTLP traces/metrics
-   `feature-profiling` - Continuous profiling
-   `feature-integrations` - Service monitoring (MySQL, PostgreSQL, Redis, etc.)
-   `feature-annotation-autodiscovery` - Annotation-based service discovery
-   `feature-auto-instrumentation` - Automatic OTEL instrumentation
-   `feature-prometheus-operator-objects` - Support for PrometheusRule/ServiceMonitor CRDs

**Destinations**: Standardized telemetry backends defined in `charts/k8s-monitoring/destinations/`:

-   `prometheus` - Prometheus remote write
-   `loki` - Loki log aggregation
-   `otlp` - OpenTelemetry Protocol
-   `pyroscope` - Continuous profiling
-   `custom` - Raw Alloy modules for custom backends

Each destination has an "ecosystem" that guides intelligent routing (e.g., cluster-metrics prefers Prometheus ecosystem).

#### Template Flow

1.  **Main Chart** (`charts/k8s-monitoring/templates/alloy-config.yaml`)
    -   Iterates through enabled collectors
    -   Includes enabled features via `features.<feature>.include`
    -   Generates destination components
    -   Creates ConfigMaps with final Alloy configuration

2.  **Feature Templates** (`charts/k8s-monitoring/templates/_feature_*.tpl`)
    -   Validates prerequisites and destinations
    -   Resolves destination assignments
    -   Includes feature module from subchart
    -   Instantiates module with destination arguments

3.  **Feature Module** (`charts/k8s-monitoring/charts/feature-*/templates/_module.alloy.tpl`)
    -   Declares Alloy module with standard arguments (`metrics_destinations`, `logs_destinations`, etc.)
    -   Composes component templates
    -   Returns complete Alloy module definition

4.  **Destination Templates** (`charts/k8s-monitoring/templates/destinations/_destination_*.tpl`)
    -   Generates Alloy components for data routing
    -   Handles authentication, TLS, retries
    -   Manages secrets and credentials

#### Generated Files

The build process generates several files (must be included in PRs):

-   `README.md` - Chart documentation from values.yaml
-   `values.schema.json` - JSON schema for values validation
-   `Chart.lock` - Dependency lock file
-   `templates/destinations/_destination_types.tpl` - Auto-generated destination types
-   `docs/examples/*/output.yaml` - Rendered example manifests
-   `docs/examples/*/alloy-*.alloy` - Extracted Alloy configurations
-   `docs/collectors/*.md` - Collector documentation
-   `docs/destinations/*.md` - Destination documentation
-   `schema-mods/definitions/*-collector.schema.json` - Collector schemas
-   `schema-mods/definitions/*-destination.schema.json` - Destination schemas

### Feature Subchart Structure

Each feature chart follows this structure:

```text
charts/k8s-monitoring/charts/feature-<name>/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _module.alloy.tpl          # Core Alloy module generation
│   ├── _notes.tpl                 # Deployment notes and self-reporting
│   ├── _validation.tpl            # Input validation
│   ├── _<component>.alloy.tpl     # Component-specific configs
│   └── configmap.yaml             # Test output
└── tests/
    └── *.yaml                     # Helm unit tests
```

Required template functions:

-   `feature.<name>.module` - Generates the Alloy module
-   `feature.<name>.notes.deployments` - Lists deployed workloads
-   `feature.<name>.notes.task` - One-line feature summary
-   `feature.<name>.notes.actions` - User action prompts
-   `feature.<name>.summary` - Self-reporting metrics

### Integrations (feature-integrations)

The integrations feature has a unique structure where each integration type has dedicated templates:

-   `templates/_integration_<service>.tpl` - Integration-specific logic
-   `templates/_integration_<service>_metrics.tpl` - Metrics collection
-   `templates/_integration_<service>_logs.tpl` - Log collection
-   `integrations/<service>-values.yaml` - Default configuration

Integrations are configured in `values.integrations.<service>.instances[]` and auto-discovered during rendering.

### Value Hierarchy

Configuration merges in this order (later overrides earlier):

1.  Upstream Alloy chart defaults
2.  Collector common defaults (`collectors/alloy-values.yaml`)
3.  Collector-specific defaults (`collectors/named-defaults/<collector>.yaml`)
4.  Global overrides (`values.global.*`)
5.  User-provided values

### Validation Strategy

The chart implements multi-level validation:

1.  **Feature Validation** - Checks destinations exist, collector requirements met
2.  **Destination Validation** - Validates type-specific fields, URLs, auth
3.  **Integration Validation** - Ensures required fields for each integration
4.  **Schema Validation** - JSON schema validates structure

Validation errors include suggestions for fixes (design idiom).

## Development Workflow

### Adding a New Feature

1.  Create feature chart directory: `charts/k8s-monitoring/charts/feature-<name>/`
2.  Add `Chart.yaml` with feature metadata
3.  Create `values.yaml` with feature-specific configuration
4.  Implement required templates:
    -   `_module.alloy.tpl` - Core module with standard arguments
    -   `_notes.tpl` - Deployment metadata and self-reporting
    -   `_validation.tpl` - Input validation
5.  Add unit tests in `tests/`
6.  Update main chart `Chart.yaml` to include as dependency
7.  Add feature template in main chart: `templates/_feature_<name>.tpl`
8.  Run `make build` to regenerate files
9.  Run `make test` to verify

See `docs/create-a-new-feature/` for detailed guide and templates.

### Adding a New Integration

1.  Create integration values: `charts/k8s-monitoring/charts/feature-integrations/integrations/<service>-values.yaml`
2.  Create integration templates:
    -   `charts/k8s-monitoring/charts/feature-integrations/templates/_integration_<service>.tpl`
    -   `charts/k8s-monitoring/charts/feature-integrations/templates/_integration_<service>_metrics.tpl`
    -   `charts/k8s-monitoring/charts/feature-integrations/templates/_integration_<service>_logs.tpl`
3.  Add to integration type registry in `_integration_types.tpl`
4.  Create documentation: `charts/k8s-monitoring/charts/feature-integrations/docs/integrations/<service>.md`
5.  Run `make -C charts/k8s-monitoring/charts/feature-integrations build`
6.  Run `make -C charts/k8s-monitoring build` to regenerate main chart files

### Adding a New Destination Type

1.  Create destination values: `charts/k8s-monitoring/destinations/<type>-values.yaml`
2.  Create destination template: `charts/k8s-monitoring/templates/destinations/_destination_<type>.tpl`
3.  Run `make build` to regenerate `_destination_types.tpl` and schemas
4.  Add documentation template (optional): `charts/k8s-monitoring/docs/destinations/.doc_templates/<type>.gotmpl`
5.  Run `make build` again to generate documentation

### Modifying Chart Values

1.  Edit `values.yaml` in the appropriate chart
2.  Run `make build` to regenerate README.md and values.schema.json
3.  If changing schema structure, update `schema-mods/*.json` or `schema-mods/*.jq`
4.  Update examples if needed: `docs/examples/*/values.yaml`
5.  Run `make test` to verify all tests pass

### Working with Examples

Examples live in `charts/k8s-monitoring/docs/examples/` and are rendered during build:

1.  Create directory with `values.yaml` and optional `description.txt`
2.  Run `make -C charts/k8s-monitoring examples` to render
3.  Generated files: `output.yaml`, `README.md`, `alloy-*.alloy`
4.  Examples are tested via shellspec in `tests/example-checks/`

## Design Principles

From CONTRIBUTING.md, these idioms guide contributions:

1.  **Ask about outcomes, not systems** - Use outcome-focused naming (e.g., `clusterMetrics` not `mega-widget`)
2.  **Error messages include suggestions** - Always tell users how to fix issues
3.  **No config language knowledge required** - Provide high-level abstractions over raw Alloy config
4.  **The right amount of magic** - Balance predictability with convenience

## Tools Required

Core tools:

-   Helm 3.14+ (required)
-   Docker (required for kind and containerized tools)
-   kind (for integration tests)
-   Grafana Alloy (for linting Alloy configs)
-   yamllint (for YAML linting)
-   chart-testing (for Helm chart linting)

Optional tools (Docker fallback available):

-   helm-docs (README generation)
-   helm-unittest (unit test execution)
-   Flux CLI (integration tests)
-   shellspec (shell-based tests)

Platform testing tools (optional):

-   gcloud (Google Cloud)
-   aws-cli & eksctl (AWS)
-   az (Azure)
-   openshift-install (OpenShift)

## Repository Structure

```text
charts/
├── k8s-monitoring/              # Main v3 chart
│   ├── charts/                  # Feature subcharts
│   │   ├── feature-cluster-metrics/
│   │   ├── feature-integrations/
│   │   └── ...
│   ├── collectors/              # Collector definitions
│   ├── destinations/            # Destination type definitions
│   ├── docs/                    # Documentation and examples
│   ├── templates/               # Main chart templates
│   │   ├── destinations/        # Destination component templates
│   │   └── _feature_*.tpl       # Feature integration templates
│   ├── tests/                   # Tests
│   │   ├── integration/         # Integration tests
│   │   └── platform/            # Platform-specific tests
│   └── values.yaml              # Main values
└── k8s-monitoring-v1/           # Legacy v1 chart

scripts/                         # Helper scripts
.github/workflows/               # CI/CD workflows
```

## Testing Strategy

**Unit Tests** (`make test`):

-   Helm unittest tests in `tests/*.yaml`
-   Test individual features and values combinations
-   Snapshot testing for rendered output
-   Runs quickly without Kubernetes cluster

**Example Checks** (`make example-checks`):

-   Shellspec tests validating example outputs
-   Ensures examples render correctly
-   Validates Alloy config syntax

**Integration Tests** (`helm-test charts/k8s-monitoring/tests/integration/<test>/`):

-   Creates kind cluster
-   Deploys chart with test values
-   Validates deployment and functionality
-   Located in `tests/integration/*/`

**Platform Tests**:

-   Tests on real cloud platforms (GKE, EKS, AKS)
-   Located in `tests/platform/*/`
-   Usually run in CI only

**Lint Checks**:

-   Alloy config syntax validation
-   Helm chart structure and conventions
-   YAML, shell, Markdown, terraform linting
-   Insensitive language checking (alex)
-   Spell checking (misspell)
-   GitHub Actions validation (actionlint, zizmor)

## Important Notes

-   Helm 3.14+ is strictly required (version check in Makefile)
-   Generated files must be committed (don't add to .gitignore)
-   Feature charts have independent version numbers (not tied to main chart version)
-   The Alloy Operator manages collector deployments (not Helm directly)
-   Each collector gets its own ConfigMap with Alloy configuration
-   Destination ecosystem matching prevents imperfect data translations
-   Features can specify multiple collectors they depend on
-   Integration tests can opt-out of rendering with `.no-render` file
