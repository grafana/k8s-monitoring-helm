{{- define "integrations.etcd.type.metrics" }}true{{- end }}
{{- define "integrations.etcd.type.logs" }}false{{- end }}

{{/* Loads the etcd module and instances */}}
{{/* Inputs: Values (all values), Files (Files object) */}}
{{- define "integrations.etcd.module.metrics" }}
declare "etcd_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
  {{- include "alloyModules.load" (deepCopy $ | merge (dict "name" "etcd" "path" "modules/databases/kv/etcd/metrics.alloy")) | nindent 2 }}

  {{- range $instance := (index $.Values "etcd").instances }}
    {{- include "integrations.etcd.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{/* Instantiates the etcd integration */}}
{{/* Inputs: integration (etcd integration definition), Values (all values), Files (Files object) */}}
{{- define "integrations.etcd.include.metrics" }}
{{- $defaultValues := "integrations/etcd-values.yaml" | .Files.Get | fromYaml }}
{{- with $defaultValues | merge (deepCopy .instance) }}
{{- $metricAllowList := .metrics.tuning.includeMetrics }}
{{- $metricDenyList := .metrics.tuning.excludeMetrics }}

{{- $componentLabelDefined := false }}
{{- $labelSelectors := list }}
{{- range $k, $v := .labelSelectors }}
  {{- if eq $k "app.kubernetes.io/component" }}{{- $componentLabelDefined = true }}{{- end }}
  {{- if $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
{{- if not $componentLabelDefined }}
  {{- $labelSelectors = append $labelSelectors (printf "app.kubernetes.io/component=%s" .name) }}
{{- end }}
{{- $fieldSelectors := list }}
{{- range $k, $v := .fieldSelectors }}
{{- $fieldSelectors = append $fieldSelectors (printf "%s=%s" $k $v) }}
{{- end }}
etcd.kubernetes {{ include "helper.alloy_name" .name | quote }} {
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

etcd.scrape {{ include "helper.alloy_name" .name | quote }} {
  targets = etcd.kubernetes.{{ include "helper.alloy_name" .name }}.output
  clustering = true
{{- if $metricAllowList }}
  keep_metrics = "up|{{ $metricAllowList |  join "|" | join "|" }}"
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

{{- define "integrations.etcd.validate" }}{{- end }}
