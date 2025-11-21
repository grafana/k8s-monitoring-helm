{{/* Inputs: . (Values) */}}
{{- define "integrations.mysql.type.metrics" }}
{{- $defaultValues := "integrations/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- $metricsEnabled := false }}
{{- range $instance := .Values.mysql.instances }}
  {{- $metricsEnabled = or $metricsEnabled (dig "metrics" "enabled" true $instance) }}
{{- end }}
{{- $metricsEnabled -}}
{{- end }}

{{/* Inputs: . (Values), instance (this MySQL instance) */}}
{{- define "integrations.mysql.datasource" }}
  {{- if .exporter.dataSourceName }}
data_source_name = {{ .exporter.dataSourceName | quote }}
  {{- else }}
    {{- $dataSourceParamList := list }}
    {{- if .exporter.dataSource.allowFallbackToPlaintext }}
      {{- $dataSourceParamList = append $dataSourceParamList (printf "allowFallbackToPlaintext=%t" .exporter.dataSource.allowFallbackToPlaintext) }}
    {{- end }}
    {{- if .exporter.dataSource.tls }}
      {{- $dataSourceParamList = append $dataSourceParamList (printf "tls=%s" .exporter.dataSource.tls) }}
    {{- end }}
    {{- $dataSourceParams := "" }}
    {{- if $dataSourceParamList }}
      {{- $dataSourceParams = printf "?%s" ($dataSourceParamList | join "&") }}
    {{- end }}
    {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.username")) "true" }}
      {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.password")) "true" }}
data_source_name = string.format("%s:%s@{{ .exporter.dataSource.protocol }}(%s:%d)/{{ $dataSourceParams }}",
  {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }},
  {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.password" "nonsensitive" true) }},
  {{ .exporter.dataSource.host | quote }},
  {{ .exporter.dataSource.port | int }},
)
      {{- else }}
data_source_name = string.format("%s@{{ .exporter.dataSource.protocol }}(%s:%d)/{{ $dataSourceParams }}",
  {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }},
  {{ .exporter.dataSource.host | quote }},
  {{ .exporter.dataSource.port | int }},
)
      {{- end }}
    {{- else if .exporter.dataSource.protocol }}
data_source_name = string.format("{{ .exporter.dataSource.protocol }}(%s:%d)/", {{ .exporter.dataSource.host | quote }}, {{ .exporter.dataSource.port | int }})
    {{- else }}
data_source_name = string.format("%s:%d/", {{ .exporter.dataSource.host | quote }}, {{ .exporter.dataSource.port | int }})
    {{- end }}
  {{- end }}
{{- end }}

{{- define "integrations.mysql.module.metrics" }}
declare "mysql_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }
  {{- range $instance := $.Values.mysql.instances }}
    {{- include "integrations.mysql.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Inputs: . (Values), instance (this MySQL instance) */}}
{{- define "integrations.mysql.include.metrics" }}
{{- $defaultValues := "integrations/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- with mergeOverwrite $defaultValues .instance (dict "type" "integration.mysql") }}
{{- if eq (include "secrets.usesKubernetesSecret" .) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" .)) | indent 0 }}
{{- end }}
{{- if .metrics.enabled }}
prometheus.exporter.mysql {{ include "helper.alloy_name" .name | quote }} {
  {{- include "integrations.mysql.datasource" . | indent 2 }}
  {{- $enabledCollectors := list }}
  {{- if kindIs "slice" .exporter.collectors }}
    {{- $enabledCollectors = .exporter.collectors }}
  {{- else }}
    {{- if .exporter.collectors.heartbeat.enabled }}
      {{- $enabledCollectors = append $enabledCollectors "heartbeat" }}
      {{- if or .exporter.collectors.heartbeat.database .exporter.collectors.heartbeat.table }}
  heartbeat {
      {{- if .exporter.collectors.heartbeat.database }}
    database = {{ .exporter.collectors.heartbeat.database | quote }}
      {{- end }}
      {{- if .exporter.collectors.heartbeat.table }}
    table = {{ .exporter.collectors.heartbeat.table | quote }}
      {{- end }}
  }
      {{- end }}
    {{- end }}
    {{- if .exporter.collectors.mysqlUser.enabled }}
      {{- $enabledCollectors = append $enabledCollectors "mysql.user" }}
      {{- if .exporter.collectors.mysqlUser.privileges }}
  mysql.user {
    privileges = true
  }
      {{- end }}
    {{- end }}
    {{- if .exporter.collectors.perfSchemaEventsStatements.enabled }}
      {{- $enabledCollectors = append $enabledCollectors "perf_schema.eventsstatements" }}
    {{- end }}
  {{- end }}
  enable_collectors = {{ $enabledCollectors | toJson }}
}
{{- end }}
{{- if .databaseObservability.enabled }}

database_observability.mysql {{ include "helper.alloy_name" .name | quote }} {
  targets = prometheus.exporter.mysql.{{ include "helper.alloy_name" .name }}.targets
  {{- include "integrations.mysql.datasource" . | indent 2 }}
  allow_update_performance_schema_settings = {{ .databaseObservability.allowUpdatePerformanceSchemaSettings }}

  {{- $enabledCollectors := list }}
  {{- if .databaseObservability.collectors.explainPlans.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "explain_plans" }}
    {{- with .databaseObservability.collectors.explainPlans }}
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
  {{- if .databaseObservability.collectors.locks.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "locks" }}
    {{- with .databaseObservability.collectors.locks }}
  locks {
    collect_interval = {{ .collectInterval | quote }}
    threshold = {{ .threshold | quote }}
  }
    {{- end }}
  {{- end }}
  {{- if .databaseObservability.collectors.queryDetails.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "query_details" }}
    {{- with .databaseObservability.collectors.queryDetails }}
  query_details {
    collect_interval = {{ .collectInterval | quote }}
  }
    {{- end }}
  {{- end }}
  {{- if .databaseObservability.collectors.querySamples.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "query_samples" }}
    {{- with .databaseObservability.collectors.querySamples }}
  query_samples {
    collect_interval = {{ .collectInterval | quote }}
    disable_query_redaction = {{ .disableQueryRedaction }}
    auto_enable_setup_consumers = {{ .autoEnableSetupConsumers }}
    setup_consumers_check_interval = {{ .setupConsumersCheckInterval | quote }}
  }
    {{- end }}
  {{- end }}
  {{- if .databaseObservability.collectors.schemaDetails.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "schema_details" }}
    {{- with .databaseObservability.collectors.schemaDetails }}
  schema_details {
    collect_interval = {{ .collectInterval | quote }}
    cache_enabled = {{ .cacheEnabled }}
    cache_size = {{ .cacheSize }}
    cache_ttl = {{ .cacheTTL | quote }}
  }
    {{- end }}
  {{- end }}
  {{- if .databaseObservability.collectors.setupConsumers.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "setup_consumers" }}
    {{- with .databaseObservability.collectors.setupConsumers }}
  setup_consumers {
    collect_interval = {{ .collectInterval | quote }}
  }
    {{- end }}
  {{- end }}
  enable_collectors = {{ $enabledCollectors | toJson }}

  forward_to = argument.logs_destinations.value
}
{{- end }}

{{- if .metrics.enabled }}
prometheus.scrape {{ include "helper.alloy_name" .name | quote }} {
  {{- if .databaseObservability.enabled }}
  targets = database_observability.mysql.{{ include "helper.alloy_name" .name }}.targets
  {{- else }}
  targets = prometheus.exporter.mysql.{{ include "helper.alloy_name" .name }}.targets
  {{- end }}
  clustering {
    enabled = true
  }

  scrape_interval = {{ .metrics.scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .metrics.scrapeTimeout | default $.Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ $.Values.global.scrapeProtocols | toJson }}
  scrape_classic_histograms = {{ $.Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ $.Values.global.scrapeNativeHistograms }}
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
    regex = "up|scrape_samples_scraped|{{ .metrics.tuning.includeMetrics | join "|" }}"
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
