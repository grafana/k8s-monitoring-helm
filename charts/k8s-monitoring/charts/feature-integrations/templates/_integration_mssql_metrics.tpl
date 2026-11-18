{{/* Inputs: . (Values) */}}
{{- define "integrations.mssql.type.metrics" }}
{{- $defaultValues := "integrations/mssql-values.yaml" | .Files.Get | fromYaml }}
{{- $metricsEnabled := false }}
{{- range $instance := .Values.mssql.instances }}
  {{- $metricsEnabled = or $metricsEnabled (dig "metrics" "enabled" true $instance) }}
{{- end }}
{{- $metricsEnabled -}}
{{- end }}

{{/* Inputs: . (Values), instance (this MSSQL instance) */}}
{{- define "integrations.mssql.datasource" }}
  {{- if .exporter.dataSourceNameFrom }}
{{ .exporter.dataSourceNameFrom }}
  {{- else if .exporter.dataSourceName }}
{{ .exporter.dataSourceName | quote }}
  {{- else }}
    {{- $dataSourceParamList := list }}
    {{- if .exporter.dataSource.database }}
      {{- $dataSourceParamList = append $dataSourceParamList (printf "database=%s" (urlquery .exporter.dataSource.database)) }}
    {{- end }}
    {{- with .exporter.dataSource.params }}
      {{- if .encrypt }}
        {{- $dataSourceParamList = append $dataSourceParamList (printf "encrypt=%s" (urlquery .encrypt)) }}
      {{- end }}
      {{- if .trustServerCertificate }}
        {{- $dataSourceParamList = append $dataSourceParamList (printf "TrustServerCertificate=%s" (urlquery .trustServerCertificate)) }}
      {{- end }}
      {{- if .hostNameInCertificate }}
        {{- $dataSourceParamList = append $dataSourceParamList (printf "hostNameInCertificate=%s" (urlquery .hostNameInCertificate)) }}
      {{- end }}
      {{- if .authenticator }}
        {{- $dataSourceParamList = append $dataSourceParamList (printf "authenticator=%s" (urlquery .authenticator)) }}
      {{- end }}
      {{- if .appName }}
        {{- $dataSourceParamList = append $dataSourceParamList (printf "app%%20name=%s" (urlquery .appName)) }}
      {{- end }}
      {{- range $k, $v := .extra }}
        {{- $dataSourceParamList = append $dataSourceParamList (printf "%s=%s" (urlquery ($k | toString)) (urlquery ($v | toString))) }}
      {{- end }}
    {{- end }}
    {{- $dataSourceParams := "" }}
    {{- if $dataSourceParamList }}
      {{- $dataSourceParams = printf "?%s" ($dataSourceParamList | join "&") }}
    {{- end }}
    {{- $hasUsername := eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.username")) "true" }}
    {{- $hasPassword := eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.password")) "true" }}
    {{- if and $hasUsername $hasPassword }}
string.format("sqlserver://%s:%s@%s:%d{{ $dataSourceParams | replace "%" "%%" }}",
  encoding.url_encode({{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }}),
  encoding.url_encode({{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.password" "nonsensitive" true) }}),
  {{ .exporter.dataSource.host | quote }},
  {{ .exporter.dataSource.port | int }},
)
    {{- else if $hasUsername }}
string.format("sqlserver://%s@%s:%d{{ $dataSourceParams | replace "%" "%%" }}",
  encoding.url_encode({{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }}),
  {{ .exporter.dataSource.host | quote }},
  {{ .exporter.dataSource.port | int }},
)
    {{- else }}
string.format("sqlserver://%s:%d{{ $dataSourceParams | replace "%" "%%" }}",
  {{ .exporter.dataSource.host | quote }},
  {{ .exporter.dataSource.port | int }},
)
    {{- end }}
  {{- end }}
{{- end }}

{{- define "integrations.mssql.module.metrics" }}
declare "mssql_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
  {{- if eq (include "integrations.mssql.type.logOutput" .) "true" }}
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }
  {{- end }}
  {{- range $instance := $.Values.mssql.instances }}
    {{- include "integrations.mssql.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Inputs: . (Values), instance (this MSSQL instance) */}}
{{- define "integrations.mssql.include.metrics" }}
{{- $defaultValues := "integrations/mssql-values.yaml" | .Files.Get | fromYaml }}
{{- $userSetJobLabel := hasKey $.instance "jobLabel" }}
{{- with mergeOverwrite $defaultValues .instance (dict "type" "integration.mssql") }}
{{- $alloyName := include "helper.alloy_name" .name }}
{{- $dbRelabelName := printf "database_observability_sqlserver_%s" $alloyName }}
{{- $jobLabel := .jobLabel }}
{{- if and .databaseObservability.enabled (not $userSetJobLabel) }}
  {{- $jobLabel = "integrations/db-o11y" }}
{{- end }}
{{- $hasTuning := or .metrics.tuning.includeMetrics .metrics.tuning.excludeMetrics .metrics.extraMetricProcessingRules }}
{{- $emitPromRelabel := or (not .databaseObservability.enabled) $hasTuning }}
{{- if eq (include "secrets.usesKubernetesSecret" .) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" .)) | indent 0 }}
{{- end }}
{{- if .metrics.enabled }}
prometheus.exporter.mssql {{ $alloyName | quote }} {
  connection_string = {{ include "integrations.mssql.datasource" . | indent 2 | trim }}
  {{- if .exporter.connectionName }}
  connection_name = {{ .exporter.connectionName | quote }}
  {{- end }}
  {{- if not (kindIs "invalid" .exporter.maxIdleConnections) }}
  max_idle_connections = {{ .exporter.maxIdleConnections | int }}
  {{- end }}
  {{- if not (kindIs "invalid" .exporter.maxOpenConnections) }}
  max_open_connections = {{ .exporter.maxOpenConnections | int }}
  {{- end }}
  {{- if .exporter.maxConnectionLifetime }}
  max_connection_lifetime = {{ .exporter.maxConnectionLifetime | quote }}
  {{- end }}
  {{- if .exporter.timeout }}
  timeout = {{ .exporter.timeout | quote }}
  {{- end }}
  {{- if .exporter.queryConfigFrom }}
  query_config = {{ .exporter.queryConfigFrom }}
  {{- else if .exporter.queryConfig }}
  query_config = {{ .exporter.queryConfig | quote }}
  {{- end }}
}
{{- end }}
{{- if .databaseObservability.enabled }}

database_observability.sql_server {{ $alloyName | quote }} {
  targets = prometheus.exporter.mssql.{{ $alloyName }}.targets
  data_source_name = {{ include "integrations.mssql.datasource" . | indent 2 | trim }}
  exclude_current_user = {{ .databaseObservability.excludeCurrentUser }}
  {{- if .databaseObservability.excludeSchemas }}
  exclude_schemas = {{ .databaseObservability.excludeSchemas | toJson }}
  {{- end }}
  {{- if .databaseObservability.excludeDatabases }}
  exclude_databases = {{ .databaseObservability.excludeDatabases | toJson }}
  {{- end }}
  {{- if .databaseObservability.excludeUsers }}
  exclude_users = {{ .databaseObservability.excludeUsers | toJson }}
  {{- end }}
  {{- if .databaseObservability.queryTimeout }}
  query_timeout = {{ .databaseObservability.queryTimeout | quote }}
  {{- end }}

  {{- with .databaseObservability.cloudProvider }}
  {{- $hasAws := and .aws .aws.arn }}
  {{- $hasAzure := and .azure .azure.subscriptionId .azure.resourceGroup }}
  {{- $hasGcp := and .gcp .gcp.connectionName }}
  {{- if or $hasAws $hasAzure $hasGcp }}
  cloud_provider {
    {{- if $hasAws }}
    aws {
      arn = {{ .aws.arn | quote }}
    }
    {{- end }}
    {{- if $hasAzure }}
    azure {
      subscription_id = {{ .azure.subscriptionId | quote }}
      resource_group = {{ .azure.resourceGroup | quote }}
      {{- if .azure.serverName }}
      server_name = {{ .azure.serverName | quote }}
      {{- end }}
    }
    {{- end }}
    {{- if $hasGcp }}
    gcp {
      connection_name = {{ .gcp.connectionName | quote }}
    }
    {{- end }}
  }
  {{- end }}
  {{- end }}

  {{- $enabledCollectors := list }}
  {{- $disabledCollectors := list }}
  {{- if .databaseObservability.collectors.explainPlans.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "explain_plans" }}
    {{- with .databaseObservability.collectors.explainPlans }}
  explain_plans {
    collect_interval = {{ .collectInterval | quote }}
  }
    {{- end }}
  {{- else }}
    {{- $disabledCollectors = append $disabledCollectors "explain_plans" }}
  {{- end }}
  {{- if .databaseObservability.collectors.queryDetails.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "query_details" }}
    {{- with .databaseObservability.collectors.queryDetails }}
  query_details {
    collect_interval = {{ .collectInterval | quote }}
  }
    {{- end }}
  {{- else }}
    {{- $disabledCollectors = append $disabledCollectors "query_details" }}
  {{- end }}
  {{- if .databaseObservability.collectors.queryMetrics.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "query_metrics" }}
    {{- with .databaseObservability.collectors.queryMetrics }}
  query_metrics {
    collect_interval = {{ .collectInterval | quote }}
    {{- if not (kindIs "invalid" .statementsLimit) }}
    statements_limit = {{ .statementsLimit | int }}
    {{- end }}
    {{- if .statementsLookback }}
    statements_lookback = {{ .statementsLookback | quote }}
    {{- end }}
  }
    {{- end }}
  {{- else }}
    {{- $disabledCollectors = append $disabledCollectors "query_metrics" }}
  {{- end }}
  {{- if .databaseObservability.collectors.querySamples.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "query_samples" }}
    {{- with .databaseObservability.collectors.querySamples }}
  query_samples {
    collect_interval = {{ .collectInterval | quote }}
    disable_query_redaction = {{ .disableQueryRedaction }}
  }
    {{- end }}
  {{- else }}
    {{- $disabledCollectors = append $disabledCollectors "query_samples" }}
  {{- end }}
  {{- if .databaseObservability.collectors.schemaDetails.enabled }}
    {{- $enabledCollectors = append $enabledCollectors "schema_details" }}
    {{- with .databaseObservability.collectors.schemaDetails }}
  schema_details {
    collect_interval = {{ .collectInterval | quote }}
  }
    {{- end }}
  {{- else }}
    {{- $disabledCollectors = append $disabledCollectors "schema_details" }}
  {{- end }}
  enable_collectors = {{ $enabledCollectors | toJson }}
  {{- if $disabledCollectors }}
  disable_collectors = {{ $disabledCollectors | toJson }}
  {{- end }}

  forward_to = [loki.relabel.{{ $dbRelabelName }}.receiver]
}

loki.relabel {{ $dbRelabelName | quote }} {
  forward_to = argument.logs_destinations.value
  rule {
    target_label = "job"
    replacement = {{ $jobLabel | quote }}
  }
  rule {
    source_labels = ["instance"]
    target_label = "dsn"
  }
  rule {
    target_label = "instance"
    replacement = {{ .name | quote }}
  }
  {{- range $label, $value := .databaseObservability.labels }}
  rule {
    target_label = {{ $label | quote }}
    replacement = {{ $value | quote }}
  }
  {{- end }}
}

discovery.relabel {{ $dbRelabelName | quote }} {
  targets = database_observability.sql_server.{{ $alloyName }}.targets
  rule {
    target_label = "job"
    replacement = {{ $jobLabel | quote }}
  }
  rule {
    source_labels = ["instance"]
    target_label = "dsn"
  }
  rule {
    target_label = "instance"
    replacement = {{ .name | quote }}
  }
  {{- range $label, $value := .databaseObservability.labels }}
  rule {
    target_label = {{ $label | quote }}
    replacement = {{ $value | quote }}
  }
  {{- end }}
}
{{- end }}

{{- if .metrics.enabled }}
prometheus.scrape {{ $alloyName | quote }} {
  {{- if .databaseObservability.enabled }}
  targets = discovery.relabel.{{ $dbRelabelName }}.output
  {{- else }}
  targets = prometheus.exporter.mssql.{{ $alloyName }}.targets
  {{- end }}
  clustering {
    enabled = true
  }

  scrape_interval = {{ .metrics.scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .metrics.scrapeTimeout | default $.Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ include "helper.scrapeProtocols" $ }}
  scrape_classic_histograms = {{ $.Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ $.Values.global.scrapeNativeHistograms }}
  {{- if $emitPromRelabel }}
  forward_to = [prometheus.relabel.{{ $alloyName }}.receiver]
  {{- else }}
  forward_to = argument.metrics_destinations.value
  {{- end }}
}

{{- if $emitPromRelabel }}

prometheus.relabel {{ $alloyName | quote }} {
  {{- include "helper.relabelCacheArguments" (dict "maxCacheSize" .metrics.maxCacheSize "cacheTTL" .metrics.cacheTTL "global" $.Values.global) | nindent 2 }}
{{- if not .databaseObservability.enabled }}
  rule {
    target_label = "instance"
    replacement = {{ .name | quote }}
  }
  rule {
    target_label = "job"
    replacement = {{ $jobLabel | quote }}
  }
{{- end }}
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
{{- end }}
