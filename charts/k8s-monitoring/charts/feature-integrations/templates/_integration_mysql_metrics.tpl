{{- define "integrations.mysql.type.metrics" }}true{{- end }}

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
  data_source_name = string.format("%s:%s@(%s:%d)/",
    {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }},
    {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.password") }},
    {{ .exporter.dataSource.host | quote }},
    {{ .exporter.dataSource.port | int }},
  )
    {{- else }}
  data_source_name = string.format("%s@(%s:%d)/",
    {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }},
    {{ .exporter.dataSource.host | quote }},
    {{ .exporter.dataSource.port | int }},
  )
    {{- end }}
  {{- else }}
  data_source_name = string.format("%s:%d/", {{ .exporter.dataSource.host | quote }}, {{ .exporter.dataSource.port | int }})
  {{- end }}
{{- end }}
  enable_collectors = {{ .exporter.collectors | toJson }}
}

{{- $metricAllowList := .metrics.tuning.includeMetrics }}
{{- $metricDenyList := .metrics.tuning.excludeMetrics }}
prometheus.scrape {{ include "helper.alloy_name" .name | quote }} {
  targets    = prometheus.exporter.mysql.{{ include "helper.alloy_name" .name }}.targets
  job_name   = {{ .jobLabel | quote }}
  forward_to = [prometheus.relabel.{{ include "helper.alloy_name" .name }}.receiver]
}

prometheus.relabel {{ include "helper.alloy_name" .name | quote }} {
  max_cache_size = {{ .metrics.maxCacheSize | default $.Values.global.maxCacheSize | int }}
  rule {
    target_label = "instance"
    replacement = {{ .name | quote }}
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
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
