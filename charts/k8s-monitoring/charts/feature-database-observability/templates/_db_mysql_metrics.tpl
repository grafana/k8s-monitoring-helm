{{/* Inputs: . (Values) */}}
{{- define "databaseObservability.mysql.type.metrics" }}
{{- $defaultValues := "databasess/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- $metricsEnabled := false }}
{{- range $instance := .Values.mysql.instances }}
  {{- $metricsEnabled = or $metricsEnabled (dig "exporter" "enabled" true $instance) }}
  {{- $metricsEnabled = or $metricsEnabled (dig "queryAnalysis" "enabled" true $instance) }}
{{- end }}
{{- $metricsEnabled -}}
{{- end }}

{{/* Inputs: . (Values), instance (this MySQL instance) */}}
{{- define "feature.databaseObservability.mysql.datasource" }}
  {{- if .dataSource.rawString }}
data_source_name = {{ .dataSource.rawString | quote }}
  {{- else }}
    {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "dataSource.auth.username")) "true" }}
      {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "dataSource.auth.password")) "true" }}
data_source_name = string.format("%s:%s@{{ .dataSource.protocol }}(%s:%d)/",
  {{ include "secrets.read" (dict "object" . "key" "dataSource.auth.username" "nonsensitive" true) }},
  {{ include "secrets.read" (dict "object" . "key" "dataSource.auth.password" "nonsensitive" true) }},
  {{ .dataSource.host | quote }},
  {{ .dataSource.port | int }},
)
      {{- else }}
data_source_name = string.format("%s@{{ .dataSource.protocol }}(%s:%d)/",
  {{ include "secrets.read" (dict "object" . "key" "dataSource.auth.username" "nonsensitive" true) }},
  {{ .dataSource.host | quote }},
  {{ .dataSource.port | int }},
)
      {{- end }}
    {{- else if .dataSource.protocol }}
data_source_name = string.format("{{ .dataSource.protocol }}(%s:%d)/", {{ .dataSource.host | quote }}, {{ .dataSource.port | int }})
    {{- else }}
data_source_name = string.format("%s:%d/", {{ .dataSource.host | quote }}, {{ .dataSource.port | int }})
    {{- end }}
  {{- end }}
{{- end }}

{{/* Inputs: . (Values), instance (this MySQL instance) */}}
{{- define "databaseObservability.mysql.metrics" }}
{{- $defaultValues := "databases/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- with mergeOverwrite $defaultValues .instance (dict "type" "databaseObservability.mysql") }}
{{- if eq (include "secrets.usesKubernetesSecret" .) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" .)) | indent 0 }}
{{- end }}
{{- if .exporter.enabled }}
prometheus.exporter.mysql {{ include "helper.alloy_name" .name | quote }} {
  {{- include "feature.databaseObservability.mysql.datasource" . | indent 2 }}
  {{- $enabledCollectors := list }}
  {{- if .exporter.collectors.heartbeat.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "heartbeat" }}
  {{- end }}
  {{- if .exporter.collectors.mysqlUser.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "mysql.user" }}
  {{- end }}
  enable_collectors = {{ $enabledCollectors | toJson }}
}
{{- end }}
{{- if .queryAnalysis.enabled }}

database_observability.mysql {{ include "helper.alloy_name" .name | quote }} {
  {{- if .exporter.enabled }}
  targets = prometheus.exporter.mysql.{{ include "helper.alloy_name" .name }}.targets
  {{- end }}
  {{- include "feature.databaseObservability.mysql.datasource" . | indent 2 }}
  allow_update_performance_schema_settings = {{ .queryAnalysis.allowUpdatePerformanceSchemaSettings }}

  {{- $enabledCollectors := list }}
  {{- if .queryAnalysis.collectors.explainPlans.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "explain_plans" }}
    {{- with .queryAnalysis.collectors.explainPlans }}
  explain_plans {
    collect_interval = {{ .collectInterval | quote }}
    {{- if .excludeSchemas }}
    exclude_schemas = {{ .excludeSchemas | toJson }}
    {{- end }}
    initial_lookback = {{ .initialLookback | quote }}
    per_collect_ratio = {{ .perCollectRatio | quote }}
  }
    {{- end }}
  {{- end }}
  {{- if .queryAnalysis.collectors.locks.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "locks" }}
    {{- with .queryAnalysis.collectors.locks }}
  locks {
    collect_interval = {{ .collectInterval | quote }}
    threshold = {{ .threshold | quote }}
  }
    {{- end }}
  {{- end }}
  {{- if .queryAnalysis.collectors.queryDetails.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "query_details" }}
    {{- with .queryAnalysis.collectors.queryDetails }}
  query_details {
    collect_interval = {{ .collectInterval | quote }}
  }
    {{- end }}
  {{- end }}
  {{- if .queryAnalysis.collectors.querySamples.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "query_samples" }}
    {{- with .queryAnalysis.collectors.querySamples }}
  query_samples {
    collect_interval = {{ .collectInterval | quote }}
    disable_query_redaction = {{ .disableQueryRedaction }}
    auto_enable_setup_consumers = {{ .autoEnableSetupConsumers }}
    setup_consumers_check_interval = {{ .setupConsumersCheckInterval | quote }}
  }
    {{- end }}
  {{- end }}
  {{- if .queryAnalysis.collectors.schemaDetails.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "schema_details" }}
    {{- with .queryAnalysis.collectors.schemaDetails }}
  schema_details {
    collect_interval = {{ .collectInterval | quote }}
    cache_enabled = {{ .cacheEnabled }}
    cache_size = {{ .cacheSize }}
    cache_ttl = {{ .cacheTTL | quote }}
  }
    {{- end }}
  {{- end }}
  {{- if .queryAnalysis.collectors.setupConsumers.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "setup_consumers" }}
    {{- with .queryAnalysis.collectors.setupConsumers }}
  setup_consumers {
    collect_interval = {{ .collectInterval | quote }}
  }
    {{- end }}
  {{- end }}
  enable_collectors = {{ $enabledCollectors | toJson }}

  forward_to = argument.logs_destinations.value
}
{{- end }}

{{- if or .exporter.enabled .queryAnalysis.enabled }}
prometheus.scrape {{ include "helper.alloy_name" .name | quote }} {
  {{- if and .exporter.enabled (not .queryAnalysis.enabled) }}
  targets = prometheus.exporter.mysql.{{ include "helper.alloy_name" .name }}.targets
  {{- else if .queryAnalysis.enabled }}
  targets = database_observability.mysql.{{ include "helper.alloy_name" .name }}.targets
  {{- end }}
  clustering {
    enabled = true
  }

  scrape_interval = {{ .metrics.scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .metrics.scrapeTimeout | default $.Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ $.Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ $.Values.global.scrapeClassicHistograms }}
  forward_to = [prometheus.relabel.{{ include "helper.alloy_name" .name }}.receiver]
}

prometheus.relabel {{ include "helper.alloy_name" .name | quote }} {
  max_cache_size = {{ .metrics.maxCacheSize | default $.Values.global.maxCacheSize | int }}
  rule {
    target_label = "instance"
    replacement = {{ .name | quote }}
  }
  rule {
    target_label = "job"
    replacement = {{ .jobLabel | quote }}
  }
{{- if .metrics.tuning.includeMetrics }}
  rule {
    source_labels = ["__name__"]
    regex = "up|scrape_samples_scraped|{{ .metrics.tuning.includeMetrics | fromYamlArray | join "|" }}"
    action = "keep"
  }
{{- end }}
{{- if .metrics.tuning.excludeMetrics }}
  rule {
    source_labels = ["__name__"]
    regex = {{ .metrics.tuning.excludeMetrics | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if .metrics.extraMetricProcessingRules }}
{{ .metrics.extraMetricProcessingRules | indent 2 }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
{{- end }}
