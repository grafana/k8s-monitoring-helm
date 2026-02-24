{{/* Inputs: . (Values) */}}
{{- define "integrations.postgresql.type.metrics" }}
{{- $defaultValues := "integrations/postgresql-values.yaml" | .Files.Get | fromYaml }}
{{- $metricsEnabled := false }}
{{- range $instance := .Values.postgresql.instances }}
  {{- $metricsEnabled = or $metricsEnabled (dig "metrics" "enabled" true $instance) }}
{{- end }}
{{- $metricsEnabled -}}
{{- end }}

{{/* Inputs: . (Values), instance (this PostgreSQL instance) */}}
{{- define "integrations.postgresql.datasource" }}
  {{- if .exporter.dataSourceNameFrom }}
{{ .exporter.dataSourceNameFrom }}
  {{- else if .exporter.dataSourceName }}
{{ .exporter.dataSourceName | quote }}
  {{- else }}
    {{- $dataSourceParamList := list }}
    {{- if .exporter.dataSource.sslmode }}
      {{- $dataSourceParamList = append $dataSourceParamList (printf "sslmode=%s" .exporter.dataSource.sslmode) }}
    {{- end }}
    {{- $dataSourceParams := "" }}
    {{- if $dataSourceParamList }}
      {{- $dataSourceParams = printf "?%s" ($dataSourceParamList | join "&") }}
    {{- end }}
    {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.username")) "true" }}
      {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.password")) "true" }}
string.format("{{ .exporter.dataSource.protocol }}://%s:%s@%s:%d/{{ .exporter.dataSource.database }}{{ $dataSourceParams }}",
  encoding.url_encode({{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }}),
  encoding.url_encode({{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.password" "nonsensitive" true) }}),
  {{ .exporter.dataSource.host | quote }},
  {{ .exporter.dataSource.port | int }},
)
      {{- else }}
string.format("{{ .exporter.dataSource.protocol }}://%s@%s:%d/{{ .exporter.dataSource.database }}{{ $dataSourceParams }}",
  encoding.url_encode({{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }}),
  {{ .exporter.dataSource.host | quote }},
  {{ .exporter.dataSource.port | int }},
)
      {{- end }}
    {{- else if .exporter.dataSource.protocol }}
string.format("{{ .exporter.dataSource.protocol }}://%s:%d/{{ .exporter.dataSource.database }}", {{ .exporter.dataSource.host | quote }}, {{ .exporter.dataSource.port | int }})
    {{- else }}
string.format("%s:%d/{{ .exporter.dataSource.database }}", {{ .exporter.dataSource.host | quote }}, {{ .exporter.dataSource.port | int }})
    {{- end }}
  {{- end }}
{{- end }}

{{- define "integrations.postgresql.module.metrics" }}
declare "postgresql_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
  {{- if eq (include "integrations.postgresql.type.logOutput" .) "true" }}
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }
  {{- end }}
  {{- range $instance := $.Values.postgresql.instances }}
    {{- include "integrations.postgresql.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{- define "integrations.postgresql.collectors" }}
  {{- $enabledCollectors := list }}
  {{- range $collector, $settings := .exporter.collectors }}
    {{- if $settings.enabled }}
      {{- if eq $collector "buffercacheSummary"           }}{{ $enabledCollectors = append $enabledCollectors "buffercache_summary" }}
      {{- else if eq $collector "databaseWraparound"      }}{{ $enabledCollectors = append $enabledCollectors "database_wraparound" }}
      {{- else if eq $collector "longRunningTransactions" }}{{ $enabledCollectors = append $enabledCollectors "long_running_transactions" }}
      {{- else if eq $collector "postmaster"              }}{{ $enabledCollectors = append $enabledCollectors "postmaster" }}
      {{- else if eq $collector "processIdle"             }}{{ $enabledCollectors = append $enabledCollectors "process_idle" }}
      {{- else if eq $collector "replicationSlot"         }}{{ $enabledCollectors = append $enabledCollectors "replication_slot" }}
      {{- else if eq $collector "statActivityAutovacuum"  }}{{ $enabledCollectors = append $enabledCollectors "stat_activity_autovacuum" }}
      {{- else if eq $collector "statBGWriter"            }}{{ $enabledCollectors = append $enabledCollectors "stat_bgwriter" }}
      {{- else if eq $collector "statCheckpointer"        }}{{ $enabledCollectors = append $enabledCollectors "stat_checkpointer" }}
      {{- else if eq $collector "statDatabase"            }}{{ $enabledCollectors = append $enabledCollectors "stat_database" }}
      {{- else if eq $collector "statProgressVacuum"      }}{{ $enabledCollectors = append $enabledCollectors "stat_progress_vacuum" }}
      {{- else if eq $collector "statStatements"          }}{{ $enabledCollectors = append $enabledCollectors "stat_statements" }}
      {{- else if eq $collector "statUserTables"          }}{{ $enabledCollectors = append $enabledCollectors "stat_user_tables" }}
      {{- else if eq $collector "statWALReceiver"         }}{{ $enabledCollectors = append $enabledCollectors "stat_wal_receiver" }}
      {{- else if eq $collector "statioUserIndexes"       }}{{ $enabledCollectors = append $enabledCollectors "statio_user_indexes" }}
      {{- else if eq $collector "statioUserTables"        }}{{ $enabledCollectors = append $enabledCollectors "statio_user_tables" }}
      {{- else if eq $collector "xlogLocation"            }}{{ $enabledCollectors = append $enabledCollectors "xlog_location" }}
      {{- else }}{{ $enabledCollectors = append $enabledCollectors $collector }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $enabledCollectors | toJson }}
{{- end }}

{{/* Inputs: . (Values), instance (this PostgreSQL instance) */}}
{{- define "integrations.postgresql.include.metrics" }}
{{- $defaultValues := "integrations/postgresql-values.yaml" | .Files.Get | fromYaml }}
{{- with mergeOverwrite $defaultValues .instance (dict "type" "integration.postgresql") }}
{{- if eq (include "secrets.usesKubernetesSecret" .) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" .)) | indent 0 }}
{{- end }}
{{- if .metrics.enabled }}
prometheus.exporter.postgres {{ include "helper.alloy_name" .name | quote }} {
  data_source_names = [{{- include "integrations.postgresql.datasource" . | indent 2 | trim }}]
  enabled_collectors = {{ include "integrations.postgresql.collectors" . }}
  {{- if .exporter.autoDiscovery.enabled }}
  autodiscovery {
    enabled = {{ .exporter.autoDiscovery.enabled }}
    {{- if .exporter.autoDiscovery.databaseAllowList }}
    database_allowlist = {{ .exporter.autoDiscovery.databaseAllowList | toJson }}
    {{- end }}
    {{- if .exporter.autoDiscovery.databaseDenyList }}
    database_denylist = {{ .exporter.autoDiscovery.databaseDenyList | toJson }}
    {{- end }}
  }
  {{- end }}
  {{- if .exporter.collectors.statStatements.enabled }}
    {{- if or .exporter.collectors.statStatements.includeQuery .exporter.collectors.statStatements.queryLength }}
  stat_statements {
    include_query = {{ .exporter.collectors.statStatements.includeQuery }}
    {{- if .exporter.collectors.statStatements.queryLength }}
    query_length = {{ .exporter.collectors.statStatements.queryLength }}
    {{- end }}
  }
    {{- end }}
  {{- end }}
  {{- if .exporter.customQueriesConfigPath }}
  custom_queries_config_path = {{ .exporter.customQueriesConfigPath | quote }}
  {{- end }}
  disable_default_metrics = {{ .exporter.disableDefaultMetrics }}
  disable_settings_metrics = {{ .exporter.disableSettingsMetrics }}
}
{{- end }}
{{- if .databaseObservability.enabled }}

database_observability.postgres {{ include "helper.alloy_name" .name | quote }} {
  targets = prometheus.exporter.postgres.{{ include "helper.alloy_name" .name }}.targets
  data_source_name = {{ include "integrations.postgresql.datasource" . | indent 2 | trim }}

  {{- with .databaseObservability.cloudProvider }}
  {{- with .aws }}
  {{- if .arn }}
  cloud_provider {
    aws {
      arn = {{ .arn | quote }}
    }
  }
  {{- end }}
  {{- end }}
  {{- end }}

  {{- $enabledCollectors := list }}
  {{- if .databaseObservability.collectors.explainPlans.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "explain_plans" }}
    {{- with .databaseObservability.collectors.explainPlans }}
  explain_plans {
    collect_interval = {{ .collectInterval | quote }}
    {{- if .excludeSchemas }}
    exclude_schemas = {{ .excludeSchemas | toJson }}
    {{- end }}
    per_collect_ratio = {{ .perCollectRatio | quote }}
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
  enable_collectors = {{ $enabledCollectors | toJson }}

  forward_to = argument.logs_destinations.value
}
{{- end }}

{{- if .metrics.enabled }}
prometheus.scrape {{ include "helper.alloy_name" .name | quote }} {
  {{- if .databaseObservability.enabled }}
  targets = database_observability.postgres.{{ include "helper.alloy_name" .name }}.targets
  {{- else }}
  targets = prometheus.exporter.postgres.{{ include "helper.alloy_name" .name }}.targets
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
