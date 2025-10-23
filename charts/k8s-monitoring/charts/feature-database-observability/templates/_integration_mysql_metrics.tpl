{{/* Inputs: . (Values), instance (this MySQL instance) */}}
{{- define "feature.databaseObservability.mysql.datasource" }}
  {{- if .dataSource.rawString }}
{{ .dataSource.rawString | quote }}
  {{- else }}
    {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "dataSource.auth.username")) "true" }}
      {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "dataSource.auth.password")) "true" }}
string.format("%s:%s@{{ .dataSource.protocol }}(%s:%d)/",
  {{ include "secrets.read" (dict "object" . "key" "dataSource.auth.username" "nonsensitive" true) }},
  {{ include "secrets.read" (dict "object" . "key" "dataSource.auth.password" "nonsensitive" true) }},
  {{ .dataSource.host | quote }},
  {{ .dataSource.port | int }},
)
      {{- else }}
string.format("%s@{{ .dataSource.protocol }}(%s:%d)/",
  {{ include "secrets.read" (dict "object" . "key" "dataSource.auth.username" "nonsensitive" true) }},
  {{ .dataSource.host | quote }},
  {{ .dataSource.port | int }},
)
      {{- end }}
    {{- else if .dataSource.protocol }}
string.format("{{ .dataSource.protocol }}(%s:%d)/", {{ .dataSource.host | quote }}, {{ .dataSource.port | int }})
    {{- else }}
string.format("%s:%d/", {{ .dataSource.host | quote }}, {{ .dataSource.port | int }})
    {{- end }}
  {{- end }}
{{- end }}

{{/* Inputs: . (Values), instance (this MySQL instance) */}}
{{- define "databaseObservability.mysql.metrics" }}
{{- $defaultValues := "instances/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- with mergeOverwrite $defaultValues .instance (dict "type" "integration.mysql") }}
{{- if eq (include "secrets.usesKubernetesSecret" .) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" .)) | nindent 0 }}
{{- end }}

{{- if .instance.exporter.enabled }}
prometheus.exporter.mysql {{ include "helper.alloy_name" .name | quote }} {
  data_source_name = {{ include "feature.databaseObservability.mysql.datasource" . }}
  enable_collectors = {{ .exporter.collectors | toJson }}
}

{{- $metricAllowList := .metrics.tuning.includeMetrics }}
{{- $metricDenyList := .metrics.tuning.excludeMetrics }}
prometheus.scrape {{ include "helper.alloy_name" .name | quote }} {
  targets          = prometheus.exporter.mysql.{{ include "helper.alloy_name" .name }}.targets
  scrape_interval  = {{ .metrics.scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  scrape_timeout   = {{ .metrics.scrapeTimeout | default $.Values.global.scrapeTimeout | quote }}
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
{{- if .metrics.extraMetricProcessingRules }}
{{ .metrics.extraMetricProcessingRules | indent 2 }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
{{- end }}
