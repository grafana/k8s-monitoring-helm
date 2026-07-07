{{- /* Per-(type, ecosystem) support flags. Kubernetes enrichment applies to every tuple. */}}
{{- define "dataProcessors.kubernetesEnrichment.supports_metrics_prometheus" }}true{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.supports_metrics_otlp" }}true{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.supports_logs_loki" }}true{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.supports_logs_otlp" }}true{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.supports_traces_otlp" }}true{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.supports_profiles_pyroscope" }}true{{ end -}}

{{- /* Per-(ecosystem, type) input target lookups. */}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.prometheus.metrics.input" }}prometheus.relabel.{{ include "helper.alloy_name" .processorName }}_in_metrics_prometheus.receiver{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.otlp.metrics.input" }}otelcol.processor.k8sattributes.{{ include "helper.alloy_name" .processorName }}_in_metrics_otlp.input{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.loki.logs.input" }}loki.relabel.{{ include "helper.alloy_name" .processorName }}_in_logs_loki.receiver{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.otlp.logs.input" }}otelcol.processor.k8sattributes.{{ include "helper.alloy_name" .processorName }}_in_logs_otlp.input{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.otlp.traces.input" }}otelcol.processor.k8sattributes.{{ include "helper.alloy_name" .processorName }}_in_traces_otlp.input{{ end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.pyroscope.profiles.input" }}pyroscope.relabel.{{ include "helper.alloy_name" .processorName }}_in_profiles_pyroscope.receiver{{ end -}}

{{- /* Per-(ecosystem, type) config slices. The label-based ecosystems (prometheus, loki,
       pyroscope) share one pipeline shape built around the experimental *.enrich
       components; the OTLP types share an otelcol.processor.k8sattributes pipeline. */}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.prometheus.metrics.config" }}
{{- include "dataProcessors.kubernetesEnrichment.alloy.labelPipeline" (dict "processor" .processor "processorName" .processorName "type" "metrics" "ecosystem" "prometheus" "relabelComponent" "prometheus.relabel" "enrichComponent" "prometheus.enrich" "matchLabelArg" "metrics_match_label") }}
{{- end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.loki.logs.config" }}
{{- include "dataProcessors.kubernetesEnrichment.alloy.labelPipeline" (dict "processor" .processor "processorName" .processorName "type" "logs" "ecosystem" "loki" "relabelComponent" "loki.relabel" "enrichComponent" "loki.enrich" "matchLabelArg" "logs_match_label") }}
{{- end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.pyroscope.profiles.config" }}
{{- include "dataProcessors.kubernetesEnrichment.alloy.labelPipeline" (dict "processor" .processor "processorName" .processorName "type" "profiles" "ecosystem" "pyroscope" "relabelComponent" "pyroscope.relabel" "enrichComponent" "pyroscope.enrich" "matchLabelArg" "profiles_match_label") }}
{{- end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.otlp.metrics.config" }}
{{- include "dataProcessors.kubernetesEnrichment.alloy.otlpPipeline" (dict "processor" .processor "processorName" .processorName "type" "metrics") }}
{{- end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.otlp.logs.config" }}
{{- include "dataProcessors.kubernetesEnrichment.alloy.otlpPipeline" (dict "processor" .processor "processorName" .processorName "type" "logs") }}
{{- end -}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.otlp.traces.config" }}
{{- include "dataProcessors.kubernetesEnrichment.alloy.otlpPipeline" (dict "processor" .processor "processorName" .processorName "type" "traces") }}
{{- end -}}

{{- /* Sanitized telemetry label names to copy from namespace targets (labels + annotations). */}}
{{- define "dataProcessors.kubernetesEnrichment.namespaceLabelsToCopy" -}}
{{- $labels := list }}
{{- range $label, $_ := (default dict .namespaceLabels) }}{{ $labels = append $labels (include "escape_label" $label) }}{{ end }}
{{- range $label, $_ := (default dict .namespaceAnnotations) }}{{ $labels = append $labels (include "escape_label" $label) }}{{ end }}
{{- $labels | toJson }}
{{- end -}}

{{- /* Sanitized telemetry label names to copy from pod targets (labels + annotations). */}}
{{- define "dataProcessors.kubernetesEnrichment.podLabelsToCopy" -}}
{{- $labels := list }}
{{- range $label, $_ := (default dict .podLabels) }}{{ $labels = append $labels (include "escape_label" $label) }}{{ end }}
{{- range $label, $_ := (default dict .podAnnotations) }}{{ $labels = append $labels (include "escape_label" $label) }}{{ end }}
{{- $labels | toJson }}
{{- end -}}

{{- /* Stable reference to the shared pod discovery for a processor. The label-based
       pipelines use it as their enrich targets; the collectorComponents hook renders the
       backing components once per collector when anything references it.
       Inputs: processorName */}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.discovery.ref" -}}
discovery.relabel.{{ include "helper.alloy_name" .processorName }}_pods.output
{{- end -}}

{{- /* Renders the chart-owned components shared by every (type, ecosystem) slice of a
       processor on a collector. Kubernetes API watches are expensive, so the pod discovery
       pair is rendered once per (collector, processor) — only when the assembled collector
       config actually references it (the OTLP pipelines use otelcol.processor.k8sattributes
       and don't need it).
       Inputs: processor, processorName, config (the collector's assembled Alloy config) */}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.collectorComponents" }}
{{- $discoveryRef := include "dataProcessors.kubernetesEnrichment.alloy.discovery.ref" (dict "processorName" .processorName) }}
{{- if contains $discoveryRef .config }}
// Processor: {{ .processorName }} (kubernetesEnrichment) — shared pod discovery
{{- include "dataProcessors.kubernetesEnrichment.alloy.discovery" (dict "processor" .processor "processorName" .processorName) }}
{{- end }}
{{- end }}

{{- /* Pod discovery pair shared by the label-based pipelines. Discovers pods, exposes the
       requested labels/annotations under their sanitized telemetry label names, and (when
       pod enrichment is wanted) builds the composite `__meta_kubernetes_namespace_pod`
       match key. Each setting maps `<telemetry label>: <Kubernetes label/annotation name>`.
       Inputs: processor, processorName */}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.discovery" }}
{{- $name := printf "%s_pods" (include "helper.alloy_name" .processorName) }}
{{- $namespaceLabels := default dict .processor.namespaceLabels }}
{{- $namespaceAnnotations := default dict .processor.namespaceAnnotations }}
{{- $podLabels := default dict .processor.podLabels }}
{{- $podAnnotations := default dict .processor.podAnnotations }}
{{- $hasNamespaceEnrichment := or (not (empty $namespaceLabels)) (not (empty $namespaceAnnotations)) }}
{{- $hasPodEnrichment := or (not (empty $podLabels)) (not (empty $podAnnotations)) }}
discovery.kubernetes {{ $name | quote }} {
  role = "pod"
{{- if $hasNamespaceEnrichment }}
  attach_metadata {
    namespace = true
  }
{{- else if and (not (empty $podLabels)) (empty $podAnnotations) }}
  selectors {
    role = "pod"
    label = {{ values $podLabels | sortAlpha | join "," | quote }}
  }
{{- end }}
} // discovery.kubernetes "{{ $name }}"
discovery.relabel {{ $name | quote }} {
  targets = discovery.kubernetes.{{ $name }}.targets
{{- if $hasPodEnrichment }}
  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_name"]
    regex = "(.+;.+)"
    target_label = "__meta_kubernetes_namespace_pod"
  }
{{- end }}
{{- range $label, $podLabel := $podLabels }}
  rule {
    source_labels = [{{ include "pod_label" $podLabel | quote }}]
    target_label = {{ include "escape_label" $label | quote }}
  }
{{- end }}
{{- range $label, $podAnnotation := $podAnnotations }}
  rule {
    source_labels = [{{ include "pod_annotation" $podAnnotation | quote }}]
    target_label = {{ include "escape_label" $label | quote }}
  }
{{- end }}
{{- range $label, $namespaceLabel := $namespaceLabels }}
  rule {
    source_labels = [{{ include "namespace_label" $namespaceLabel | quote }}]
    target_label = {{ include "escape_label" $label | quote }}
  }
{{- end }}
{{- range $label, $namespaceAnnotation := $namespaceAnnotations }}
  rule {
    source_labels = [{{ include "namespace_annotation" $namespaceAnnotation | quote }}]
    target_label = {{ include "escape_label" $label | quote }}
  }
{{- end }}
} // discovery.relabel "{{ $name }}"
{{- end }}

{{- /* Enrichment pipeline for the label-based ecosystems. Telemetry is matched to
       namespaces via its `namespace` label and to pods via a composite namespace+pod key.
       The enrich stages read targets from the processor's shared pod discovery, which the
       collectorComponents hook renders once per collector. Built from the experimental
       *.enrich components, so collectors running this slice must set
       `alloy.stabilityLevel: experimental`.
       Inputs: processor, processorName, type, ecosystem,
               relabelComponent (e.g. prometheus.relabel),
               enrichComponent (e.g. prometheus.enrich),
               matchLabelArg (e.g. metrics_match_label) */}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.labelPipeline" }}
{{- $p := include "helper.alloy_name" .processorName }}
{{- $suffix := printf "%s_%s" .type .ecosystem }}
{{- $namespaceLabels := default dict (dig "namespaceLabels" dict .processor) }}
{{- $namespaceAnnotations := default dict (dig "namespaceAnnotations" dict .processor) }}
{{- $podLabels := default dict (dig "podLabels" dict .processor) }}
{{- $podAnnotations := default dict (dig "podAnnotations" dict .processor) }}
{{- $hasNamespaceEnrichment := or (not (empty $namespaceLabels)) (not (empty $namespaceAnnotations)) }}
{{- $hasPodEnrichment := or (not (empty $podLabels)) (not (empty $podAnnotations)) }}
{{- $outputSink := include "pipeline.alloy.outputSink.ref" (dict "processor" .processorName "type" .type "ecosystem" .ecosystem) }}
{{- $discoveryRef := include "dataProcessors.kubernetesEnrichment.alloy.discovery.ref" (dict "processorName" .processorName) }}
{{ .relabelComponent }} "{{ $p }}_in_{{ $suffix }}" {
{{- if $hasPodEnrichment }}
  rule {
    source_labels = ["namespace", "pod"]
    regex = "(.+;.+)"
    target_label = "__meta_kubernetes_namespace_pod"
  }
{{- end }}
{{- if eq .relabelComponent "loki.relabel" }}
  max_cache_size = 100
{{- end }}
{{- if $hasNamespaceEnrichment }}
  forward_to = [{{ .enrichComponent }}.{{ $p }}_ns_{{ $suffix }}.receiver]
{{- else }}
  forward_to = [{{ .enrichComponent }}.{{ $p }}_pod_{{ $suffix }}.receiver]
{{- end }}
} // {{ .relabelComponent }} "{{ $p }}_in_{{ $suffix }}"
{{- if $hasNamespaceEnrichment }}
{{ .enrichComponent }} "{{ $p }}_ns_{{ $suffix }}" {
  targets = {{ $discoveryRef }}
  target_match_label = "__meta_kubernetes_namespace"
  {{ .matchLabelArg }} = "namespace"
  labels_to_copy = {{ include "dataProcessors.kubernetesEnrichment.namespaceLabelsToCopy" .processor }}
{{- if $hasPodEnrichment }}
  forward_to = [{{ .enrichComponent }}.{{ $p }}_pod_{{ $suffix }}.receiver]
{{- else }}
  forward_to = [{{ $outputSink }}]
{{- end }}
} // {{ .enrichComponent }} "{{ $p }}_ns_{{ $suffix }}"
{{- end }}
{{- if $hasPodEnrichment }}
{{ .enrichComponent }} "{{ $p }}_pod_{{ $suffix }}" {
  targets = {{ $discoveryRef }}
  target_match_label = "__meta_kubernetes_namespace_pod"
  labels_to_copy = {{ include "dataProcessors.kubernetesEnrichment.podLabelsToCopy" .processor }}
  forward_to = [{{ .relabelComponent }}.{{ $p }}_cleanup_{{ $suffix }}.receiver]
} // {{ .enrichComponent }} "{{ $p }}_pod_{{ $suffix }}"
{{ .relabelComponent }} "{{ $p }}_cleanup_{{ $suffix }}" {
  rule {
    action = "labeldrop"
    regex = "__meta_kubernetes_namespace_pod"
  }
{{- if eq .relabelComponent "loki.relabel" }}
  max_cache_size = 100
{{- end }}
  forward_to = [{{ $outputSink }}]
} // {{ .relabelComponent }} "{{ $p }}_cleanup_{{ $suffix }}"
{{- end }}
{{- end }}

{{- /* Enrichment pipeline for OTLP telemetry, built on otelcol.processor.k8sattributes.
       Telemetry is associated to its source pod via Kubernetes resource attributes (or the
       sender's connection address), then the requested namespace/pod labels and
       annotations are attached as resource attributes under their original key names.
       Inputs: processor, processorName, type (metrics | logs | traces) */}}
{{- define "dataProcessors.kubernetesEnrichment.alloy.otlpPipeline" }}
{{- $p := include "helper.alloy_name" .processorName }}
{{- $outputSink := include "pipeline.alloy.outputSink.ref" (dict "processor" .processorName "type" .type "ecosystem" "otlp") }}
otelcol.processor.k8sattributes "{{ $p }}_in_{{ .type }}_otlp" {
  extract {
    metadata = []
{{- range $label, $podLabel := default dict (dig "podLabels" dict .processor) }}
    label {
      from = "pod"
      key = {{ $podLabel | quote }}
      tag_name = {{ $label | quote }}
    }
{{- end }}
{{- range $label, $podAnnotation := default dict (dig "podAnnotations" dict .processor) }}
    annotation {
      from = "pod"
      key = {{ $podAnnotation | quote }}
      tag_name = {{ $label | quote }}
    }
{{- end }}
{{- range $label, $namespaceLabel := default dict (dig "namespaceLabels" dict .processor) }}
    label {
      from = "namespace"
      key = {{ $namespaceLabel | quote }}
      tag_name = {{ $label | quote }}
    }
{{- end }}
{{- range $label, $namespaceAnnotation := default dict (dig "namespaceAnnotations" dict .processor) }}
    annotation {
      from = "namespace"
      key = {{ $namespaceAnnotation | quote }}
      tag_name = {{ $label | quote }}
    }
{{- end }}
  }
  pod_association {
    source {
      from = "resource_attribute"
      name = "k8s.pod.name"
    }
    source {
      from = "resource_attribute"
      name = "k8s.namespace.name"
    }
  }
  pod_association {
    source {
      from = "resource_attribute"
      name = "k8s.pod.ip"
    }
  }
  pod_association {
    source {
      from = "resource_attribute"
      name = "k8s.pod.uid"
    }
  }
  pod_association {
    source {
      from = "connection"
    }
  }
  output {
    {{ .type }} = [{{ $outputSink }}]
  }
} // otelcol.processor.k8sattributes "{{ $p }}_in_{{ .type }}_otlp"
{{- end }}

{{- /* Values-time validation for a kubernetesEnrichment processor definition. */}}
{{- define "dataProcessors.kubernetesEnrichment.validate" }}
{{- $namespaceLabels := default dict (dig "namespaceLabels" dict .processor) }}
{{- $namespaceAnnotations := default dict (dig "namespaceAnnotations" dict .processor) }}
{{- $podLabels := default dict (dig "podLabels" dict .processor) }}
{{- $podAnnotations := default dict (dig "podAnnotations" dict .processor) }}
{{- if and (empty $namespaceLabels) (empty $namespaceAnnotations) (empty $podLabels) (empty $podAnnotations) }}
  {{- $msg := list "" (printf "The processor %q does not have anything to enrich with." .processorName) }}
  {{- $msg = append $msg "Please set at least one of namespaceLabels, namespaceAnnotations, podLabels, or podAnnotations. For example:" }}
  {{- $msg = append $msg "dataProcessors:" }}
  {{- $msg = append $msg (printf "  %s:" .processorName) }}
  {{- $msg = append $msg "    type: kubernetesEnrichment" }}
  {{- $msg = append $msg "    podLabels:" }}
  {{- $msg = append $msg "      app_name: app.kubernetes.io/name" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- range $setting := list "namespaceLabels" "namespaceAnnotations" "podLabels" "podAnnotations" }}
  {{- range $label, $source := default dict (dig $setting dict $.processor) }}
    {{- if not $source }}
      {{- fail (printf "The processor %q has an empty value for %s.%s. Please set it to the name of the Kubernetes label or annotation to copy." $.processorName $setting $label) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{- /* Per-(feature, type, ecosystem) validation. The prometheus, loki, and pyroscope
       pipelines use experimental Alloy components, so the collector that runs the feature
       must use the experimental stability level. The OTLP pipelines use generally
       available components and need no special handling.
       Inputs: root, featureKey, featureName, processorName, processor, type, ecosystem */}}
{{- define "dataProcessors.kubernetesEnrichment.validate.feature" }}
{{- if has .ecosystem (list "prometheus" "loki" "pyroscope") }}
  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" .root.Values "Files" .root.Files "Subcharts" .root.Subcharts "featureKey" .featureKey) | trim }}
  {{- if $collectorName }}
    {{- $collectorValues := include "collector.alloy.values" (dict "Values" .root.Values "Files" .root.Files "collectorName" $collectorName) | fromYaml }}
    {{- $stabilityLevel := dig "alloy" "stabilityLevel" "generally-available" $collectorValues }}
    {{- if ne $stabilityLevel "experimental" }}
      {{- $msg := list "" (printf "The processor %q requires Alloy to use the experimental stability level when enriching %s." .processorName .type) }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" $collectorName) }}
      {{- $msg = append $msg "    alloy:" }}
      {{- $msg = append $msg "      stabilityLevel: experimental" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
