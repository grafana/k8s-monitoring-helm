{{- define "integrations.cert-manager.type.metrics" }}true{{- end }}
{{- define "integrations.cert-manager.type.logs" }}false{{- end }}

{{/* Loads the cert-manager module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{- define "integrations.cert-manager.module.metrics" }}
declare "cert_manager_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

  import.git "cert_manager" {
    repository = "https://github.com/grafana/alloy-modules.git"
    revision = "main"
    path = "modules/kubernetes/cert-manager/metrics.alloy"
    pull_frequency = "15m"
  }

  {{- range $instance := (index $.Values "cert-manager").instances }}
    {{- include "integrations.cert-manager.include.metrics" (dict "integration" $instance "Values" $.Values "Files" $.Files) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the cert-manager integration */}}
{{/* Inputs: integration (cert-manager integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.cert-manager.include.metrics" }}
{{- $defaultValues := "integrations/cert-manager-values.yaml" | .Files.Get | fromYaml }}
{{- with merge .integration $defaultValues }}
{{- $metricAllowList := .metricsTuning.includeMetrics }}
{{- $metricDenyList := .metricsTuning.excludeMetrics }}
{{- $labelSelectors := list }}
{{- range $k, $v := .labelSelectors }}
{{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
{{- end }}
{{- $fieldSelectors := list }}
{{- range $k, $v := .fieldSelectors }}
{{- $fieldSelectors = append $fieldSelectors (printf "%s=%s" $k $v) }}
{{- end }}
cert_manager.kubernetes {{ include "helper.alloy_name" .name | quote }} {
{{- if .namespaces }}
  namespaces = {{ .namespaces | toJson }}
{{- end }}
{{- if $labelSelectors }}
  label_selectors = {{ $labelSelectors | toJson }}
{{- end }}
{{- if $fieldSelectors }}
  field_selectors = {{ $fieldSelectors | toJson }}
{{- end }}
  port_name  = {{ .portName | quote }}
}

cert_manager.scrape {{ include "helper.alloy_name" .name | quote }} {
  targets = cert_manager.kubernetes.{{ include "helper.alloy_name" .name }}.output
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList |  join "|" | join "|" }}"
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  max_cache_size = {{ .maxCacheSize | default $.Values.global.maxCacheSize | int }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
