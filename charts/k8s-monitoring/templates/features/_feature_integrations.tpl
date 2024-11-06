{{- define "features.integrations.enabled" }}
{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations) | fromYamlArray }}
{{- $logIntegrations := include "feature.integrations.configured.logs" (dict "Values" .Values.integrations) | fromYamlArray }}
{{- if or $metricIntegrations $logIntegrations }}true{{ else }}false{{ end }}
{{- end }}

{{- define "features.integrations.collectors" }}
{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations) | fromYamlArray }}
{{- $logIntegrations := include "feature.integrations.configured.logs" (dict "Values" .Values.integrations) | fromYamlArray }}
{{- if (not (empty $metricIntegrations)) }}
- {{ .Values.integrations.collectors.metrics }}
{{- end }}
{{- if (not (empty $logIntegrations)) }}
- {{ .Values.integrations.collectors.logs }}
{{- end }}
{{- end }}

{{- define "features.integrations.metrics.include" }}
{{- $values := dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files "Release" $.Release }}
{{- $destinations := include "features.integrations.destinations.metrics" . | fromYamlArray }}
{{- $integrations := include "feature.integrations.configured.metrics" $values | fromYamlArray }}
{{- range $integrationType := $integrations }}
  {{- include (printf "integrations.%s.module.metrics" $integrationType) $values | indent 0 }}
{{ include "helper.alloy_name" $integrationType }}_integration "integration" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end }}
{{- end }}

{{- define "features.integrations.logs.include" }}
{{- $values := dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files "Release" $.Release }}
{{- $destinations := include "features.integrations.destinations.logs" . | fromYamlArray }}
{{- $integrations := include "feature.integrations.configured.logs" $values | fromYamlArray }}
{{- range $integrationType := $integrations }}
  {{- include (printf "integrations.%s.module.metrics" $integrationType) $values | indent 0 }}
{{ include "helper.alloy_name" $integrationType }}_integration "integration" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- end }}
{{- end }}

{{- define "features.integrations.include" }}
{{- if eq .collectorName .Values.integrations.collectors.metrics }}
  {{ include "features.integrations.metrics.include" . | indent 0 }}
{{- end }}
{{- if eq .collectorName .Values.integrations.collectors.logs }}
  {{ include "features.integrations.logs.include" . | indent 0 }}
{{- end }}
{{- end }}

{{- define "features.integrations.destinations" }}
{{- $metricDestinations := include "features.integrations.destinations.metrics" . | fromYamlArray }}
{{- $logDestinations := include "features.integrations.destinations.logs" . | fromYamlArray }}
{{- concat $metricDestinations $logDestinations | uniq | toYaml }}
{{- end }}

{{- define "features.integrations.destinations.metrics" }}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.integrations.destinations) -}}
{{- end }}

{{- define "features.integrations.destinations.logs" }}
[]
{{- end }}

{{- define "features.integrations.validate" }}
{{- if eq (include "features.integrations.enabled" .) "true" }}
{{- $featureName := "Service Integrations" }}

{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations) | fromYamlArray }}
{{- if $metricIntegrations }}
  {{- $metricDestinations := include "features.integrations.destinations.metrics" . | fromYamlArray }}
  {{- include "destinations.validate_destination_list" (dict "destinations" $metricDestinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" "alloy-metrics" "feature" $featureName) }}
{{- end }}

{{- $logIntegrations := include "feature.integrations.configured.logs" (dict "Values" .Values.integrations) | fromYamlArray }}
{{- if $logIntegrations }}
  {{- $logDestinations := include "features.integrations.destinations.logs" . | fromYamlArray }}
  {{- include "destinations.validate_destination_list" (dict "destinations" $logDestinations "type" "log" "ecosystem" "loki" "feature" $featureName) }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" "alloy-logs" "feature" $featureName) }}
{{- end }}
{{- end }}
{{- end }}
