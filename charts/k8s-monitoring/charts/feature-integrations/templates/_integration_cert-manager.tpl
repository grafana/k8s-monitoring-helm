{{- define "integrations.cert-manager.type.metrics" }}true{{- end }}
{{- define "integrations.cert-manager.type.logs" }}false{{- end }}

{{/* Loads the cert-manager module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{- define "integrations.cert-manager.module.metrics" }}
declare "cert_manager_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
  {{- include "alloyModules.load" (deepCopy $ | merge (dict "name" "cert_manager" "path" "modules/kubernetes/cert-manager/metrics.alloy")) | nindent 2 }}

  {{- range $instance := (index $.Values "cert-manager").instances }}
    {{- include "integrations.cert-manager.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the cert-manager integration */}}
{{/* Inputs: integration (cert-manager integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.cert-manager.include.metrics" }}
{{- $defaultValues := "integrations/cert-manager-values.yaml" | .Files.Get | fromYaml }}
{{- with $defaultValues | merge (deepCopy .instance) }}
{{- $metricAllowList := .metrics.tuning.includeMetrics }}
{{- $metricDenyList := .metrics.tuning.excludeMetrics }}

{{- $nameLabelDefined := false }}
{{- $labelSelectors := list }}
{{- range $k, $v := .labelSelectors }}
  {{- if eq $k "app.kubernetes.io/name" }}{{- $nameLabelDefined = true }}{{- end }}
  {{- if $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
{{- if not $nameLabelDefined }}
  {{- $labelSelectors = append $labelSelectors (printf "app.kubernetes.io/name=%s" .name) }}
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
  port_name = {{ .metrics.portName | quote }}
}

cert_manager.scrape {{ include "helper.alloy_name" .name | quote }} {
  targets = cert_manager.kubernetes.{{ include "helper.alloy_name" .name }}.output
  clustering = true
  job_label = {{ .jobName | quote }}
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList |  join "|" }}"
{{- end }}
{{- if $metricDenyList }}
  drop_metrics = {{ $metricDenyList | join "|" | quote }}
{{- end }}
  scrape_interval = {{ .scrapeInterval | default $.Values.global.scrapeInterval | quote }}
  max_cache_size = {{ .metrics.maxCacheSize | default $.Values.global.maxCacheSize | int }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}

{{- define "integrations.cert-manager.validate" }}{{- end }}
