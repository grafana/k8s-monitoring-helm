---
name: Add New Feature
description: Guide Claude through creating a new feature subchart for k8s-monitoring
---

# Add New Feature to k8s-monitoring

This skill guides you through creating a new feature subchart for the k8s-monitoring Helm chart.

## Prerequisites

Before starting, understand:

-   What telemetry data this feature collects (metrics, logs, traces, profiles)
-   Which collector(s) it should use (alloy-metrics, alloy-logs, alloy-singleton, alloy-receiver, alloy-profiles)
-   What destination types it needs (Prometheus, Loki, otlp, pyroscope)
-   Any external dependencies (e.g., kube-state-metrics, node-exporter)

## Steps

### 1. Create Feature Chart Directory

```bash
mkdir -p charts/k8s-monitoring/charts/feature-<name>
cd charts/k8s-monitoring/charts/feature-<name>
```

### 2. Create Chart.yaml

```yaml
apiVersion: v2
name: feature-<name>
description: <Brief description of what this feature does>
type: application
version: 1.0.0
```

### 3. Create values.yaml

Include:

-   `enabled: false` (features default to off)
-   Feature-specific configuration options
-   Follow the design idiom: ask about outcomes, not systems

### 4. Create Required Templates

**templates/\_module.alloy.tpl** - Core Alloy module:

```go
{{- define "feature.<name>.module" }}
{{- $values := .Values }}
declare "<feature_name>" {
  argument "metrics_destinations" {
    comment = "destinations for metrics"
    optional = true
  }

  argument "logs_destinations" {
    comment = "destinations for logs"
    optional = true
  }

  // Your Alloy configuration here
}
{{- end }}
```

**templates/\_notes.tpl** - Required metadata functions:

```go
{{- define "feature.<name>.notes.deployments" }}
- <list of workloads this feature deploys>
{{- end }}

{{- define "feature.<name>.notes.task" }}
<One-line summary of what this feature does>
{{- end }}

{{- define "feature.<name>.notes.actions" }}
{{- end }}

{{- define "feature.<name>.summary" }}
version: 1.0.0
enabled: {{ .Values.enabled }}
{{- end }}
```

**templates/\_validation.tpl** - Input validation:

```go
{{- define "feature.<name>.validate" }}
{{- if .Values.enabled }}
  {{- if not .Values.requiredField }}
    {{- fail "Error: feature-<name> requires requiredField to be set!\nPlease set:\nfeature<Name>:\n  requiredField: <value>" }}
  {{- end }}
{{- end }}
{{- end }}
```

### 5. Add Unit Tests

Create `tests/*.yaml` with helm-unittest test cases.

### 6. Update Main Chart

Add dependency in `charts/k8s-monitoring/Chart.yaml`:

```yaml
dependencies:
  - name: feature-<name>
    version: "1.0.0"
    repository: file://charts/feature-<name>
    condition: <featureName>.enabled
```

### 7. Create Feature Integration Template

Create `charts/k8s-monitoring/templates/_feature_<name>.tpl`:

```go
{{- define "features.<name>.collectors" }}
- alloy-metrics  # or appropriate collector
{{- end }}

{{- define "features.<name>.destinations" }}
{{- $destinations := include "destinations.get" (dict "type" "prometheus" "ecosystem" "prometheus" "context" .) | fromYamlArray }}
{{- $destinations | toYaml }}
{{- end }}

{{- define "features.<name>.include" }}
{{- if .Values.<featureName>.enabled }}
{{- $destinations := include "features.<name>.destinations" . | fromYamlArray }}
// Feature: <Feature Name>
{{- include "feature.<name>.module" (dict "Values" .Values.<featureName> "Chart" .Subcharts "context" .) }}
<feature_name> "feature" {
  metrics_destinations = [{{ include "destinations.alloy.targets" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus") }}]
}
{{- end }}
{{- end }}
```

### 8. Build and Test

```bash
# Build feature chart
make -C charts/k8s-monitoring/charts/feature-<name> build

# Update main chart dependencies
rm charts/k8s-monitoring/Chart.lock
make -C charts/k8s-monitoring build

# Run tests
make -C charts/k8s-monitoring/charts/feature-<name> test
make -C charts/k8s-monitoring test
```

### 9. Create Example

Create example in `charts/k8s-monitoring/docs/examples/features/<name>/`:

-   `values.yaml` - Example configuration
-   `description.txt` - Feature description

Then run:

```bash
make -C charts/k8s-monitoring examples
```

## Design Principles to Follow

1.  **Ask about outcomes, not systems** - Use user-friendly naming
2.  **Error messages include suggestions** - Always tell users how to fix issues
3.  **No config language knowledge required** - Provide high-level abstractions
4.  **The right amount of magic** - Balance predictability with convenience

## Validation Checklist

<!-- textlint-disable no-todo -->

-   [ ] Feature chart has all required templates (module.alloy.tpl, notes.tpl, validation.tpl)
-   [ ] Unit tests pass
-   [ ] Main chart builds successfully with feature included
-   [ ] Example renders without errors
-   [ ] Generated Alloy config is valid (checked by lint-alloy)
-   [ ] Feature follows design idioms from CONTRIBUTING.md
-   [ ] Documentation is clear and includes examples

<!-- textlint-enable no-todo -->
