{{/* Inputs: . (Values) */}}
{{- define "integrations.mysql.type.metrics" }}
{{- $defaultValues := "integrations/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- $metricsEnabled := false }}
{{- range $instance := .Values.mysql.instances }}
  {{- $metricsEnabled = or $metricsEnabled (dig "metrics" "enabled" true $instance) }}
{{- end }}
{{- $metricsEnabled -}}
{{- end }}

{{- define "integrations.mysql.module.metrics" }}
declare "mysql_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
  {{- range $instance := $.Values.mysql.instances }}
    {{- include "integrations.mysql.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{- define "integrations.mysql.include.metrics" }}
{{- $defaultValues := "integrations/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- with mergeOverwrite $defaultValues .instance (dict "type" "integration.mysql") }}
{{- if eq (include "secrets.usesKubernetesSecret" .) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" .)) | nindent 0 }}
{{- end }}
prometheus.exporter.mysql {{ include "helper.alloy_name" .name | quote }} {
{{- if .exporter.dataSourceName }}
  data_source_name  = {{ .exporter.dataSourceName | quote }}
{{- else }}
  {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.username")) "true" }}
    {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.password")) "true" }}
  data_source_name = string.format("%s:%s@{{ .exporter.dataSource.protocol }}(%s:%d)/",
    {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }},
    {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.password" "nonsensitive" true) }},
    {{ .exporter.dataSource.host | quote }},
    {{ .exporter.dataSource.port | int }},
  )
    {{- else }}
  data_source_name = string.format("%s@{{ .exporter.dataSource.protocol }}(%s:%d)/",
    {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }},
    {{ .exporter.dataSource.host | quote }},
    {{ .exporter.dataSource.port | int }},
  )
    {{- end }}
  {{- else }}
    {{- if .exporter.dataSource.protocol }}
  data_source_name = string.format("{{ .exporter.dataSource.protocol }}(%s:%d)/", {{ .exporter.dataSource.host | quote }}, {{ .exporter.dataSource.port | int }})
    {{- else }}
  data_source_name = string.format("%s:%d/", {{ .exporter.dataSource.host | quote }}, {{ .exporter.dataSource.port | int }})
    {{- end }}
  {{- end }}
{{- end }}
  enable_collectors = {{ .exporter.collectors | toJson }}
}

{{- $metricAllowList := .metrics.tuning.includeMetrics }}
{{- $metricDenyList := .metrics.tuning.excludeMetrics }}
prometheus.scrape {{ include "helper.alloy_name" .name | quote }} {
  targets    = prometheus.exporter.mysql.{{ include "helper.alloy_name" .name }}.targets
  scrape_interval = {{ .metrics.scrapeInterval | default .scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .metrics.scrapeTimeout | default .scrapeTimeout | default $.Values.global.scrapeTimeout | quote }}
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
{{- if $metricAllowList }}
  rule {
    source_labels = ["__name__"]
    regex = "up|scrape_samples_scraped|{{ $metricAllowList | fromYamlArray | join "|" }}"
    action = "keep"
  }
{{- end }}
{{- if $metricDenyList }}
  rule {
    source_labels = ["__name__"]
    regex = {{ $metricDenyList | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- if .extraMetricProcessingRules }}
{{ .extraMetricProcessingRules | indent 2 }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
