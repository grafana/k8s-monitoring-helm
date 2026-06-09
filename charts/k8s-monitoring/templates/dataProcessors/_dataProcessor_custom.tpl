{{- define "secrets.list.custom-dataProcessor" }}{{ end -}}

{{- /* Per-type validation hooks. The custom processor has nothing extra to validate. */}}
{{- define "dataProcessors.custom.validate" }}{{ end -}}
{{- define "dataProcessors.custom.validate.feature" }}{{ end -}}

{{- /* Per-collector shared components hook. The custom processor renders everything inside
       its per-(type, ecosystem) config blocks, so there is nothing shared to render. */}}
{{- define "dataProcessors.custom.alloy.collectorComponents" }}{{ end -}}

{{- /* Per-(type, ecosystem) support flags. */}}
{{- define "dataProcessors.custom.supports_metrics_prometheus" }}{{ dig "metrics" "prometheus" "enabled" false . }}{{ end -}}
{{- define "dataProcessors.custom.supports_metrics_otlp" }}{{ dig "metrics" "otlp" "enabled" false . }}{{ end -}}
{{- define "dataProcessors.custom.supports_logs_loki" }}{{ dig "logs" "loki" "enabled" false . }}{{ end -}}
{{- define "dataProcessors.custom.supports_logs_otlp" }}{{ dig "logs" "otlp" "enabled" false . }}{{ end -}}
{{- define "dataProcessors.custom.supports_traces_otlp" }}{{ dig "traces" "otlp" "enabled" false . }}{{ end -}}
{{- define "dataProcessors.custom.supports_profiles_pyroscope" }}{{ dig "profiles" "pyroscope" "enabled" false . }}{{ end -}}

{{- /* Per-(ecosystem, type) input target lookups. */}}
{{- define "dataProcessors.custom.alloy.prometheus.metrics.input" }}{{ .processor.metrics.prometheus.input }}{{ end -}}
{{- define "dataProcessors.custom.alloy.otlp.metrics.input" }}{{ .processor.metrics.otlp.input }}{{ end -}}
{{- define "dataProcessors.custom.alloy.loki.logs.input" }}{{ .processor.logs.loki.input }}{{ end -}}
{{- define "dataProcessors.custom.alloy.otlp.logs.input" }}{{ .processor.logs.otlp.input }}{{ end -}}
{{- define "dataProcessors.custom.alloy.otlp.traces.input" }}{{ .processor.traces.otlp.input }}{{ end -}}
{{- define "dataProcessors.custom.alloy.pyroscope.profiles.input" }}{{ .processor.profiles.pyroscope.input }}{{ end -}}

{{- /* Per-(ecosystem, type) user config slices. Each emits the raw Alloy block defined
       for that pipeline; an empty/missing block emits nothing. */}}
{{- define "dataProcessors.custom.alloy.prometheus.metrics.config" }}{{ dig "metrics" "prometheus" "config" "" .processor | trim }}{{ end -}}
{{- define "dataProcessors.custom.alloy.otlp.metrics.config" }}{{ dig "metrics" "otlp" "config" "" .processor | trim }}{{ end -}}
{{- define "dataProcessors.custom.alloy.loki.logs.config" }}{{ dig "logs" "loki" "config" "" .processor | trim }}{{ end -}}
{{- define "dataProcessors.custom.alloy.otlp.logs.config" }}{{ dig "logs" "otlp" "config" "" .processor | trim }}{{ end -}}
{{- define "dataProcessors.custom.alloy.otlp.traces.config" }}{{ dig "traces" "otlp" "config" "" .processor | trim }}{{ end -}}
{{- define "dataProcessors.custom.alloy.pyroscope.profiles.config" }}{{ dig "profiles" "pyroscope" "config" "" .processor | trim }}{{ end -}}
