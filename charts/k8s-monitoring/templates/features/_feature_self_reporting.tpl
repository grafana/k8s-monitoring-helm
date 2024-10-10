{{- define "features.self_reporting.enabled" -}}{{ .Values.selfReporting.enabled }}{{- end -}}
{{- define "features.self_reporting.collector" -}}
{{- if .Values.selfReporting.enabled}}
  {{- $collectorsByPreference := list "alloy-profiles" "alloy-logs" "alloy-receiver" "alloy-metrics" "alloy-singleton" }}
  {{- $chosenCollector := "" }}
  {{- range $collector := $collectorsByPreference }}
    {{- if (index $.Values $collector).enabled }}{{- $chosenCollector = $collector }}{{- end -}}
  {{- end -}}
  {{- $chosenCollector -}}
  {{- end -}}
{{- end }}

{{- define "features.self_reporting.features" }}
{{- $features := list }}
{{- range $feature := ((include "features.list" .) | fromYamlArray ) }}
  {{- if eq (include (printf "features.%s.enabled" $feature) $) "true" }}
    {{- $features = append $features $feature }}
  {{- end }}
{{- end }}
{{- $features | join "," }}
{{- end }}

{{- define "features.self_reporting.destinations" }}
{{- $features := list }}
{{- range $feature := ((include "features.list" .) | fromYamlArray ) }}
  {{- if eq (include (printf "features.%s.enabled" $feature) $) "true" }}
    {{- $features = append $features $feature }}
  {{- end }}
{{- end }}
{{- $features | join "," }}
{{- end }}

{{- define "features.self_reporting.collectors" }}
{{- $collectors := list }}
{{- range $collector := ((include "collectors.list" .) | fromYamlArray ) }}
  {{- if (index $.Values $collector).enabled }}
    {{- $collectors = append $collectors $collector }}
  {{- end }}
{{- end }}
{{- $collectors | join "," }}
{{- end }}

{{- define "features.self_reporting.file" -}}
{{- $collectors := include "features.self_reporting.collectors" . }}
{{- $features := include "features.self_reporting.features" . }}
self-reporting-metric.prom: |
  # HELP grafana_kubernetes_monitoring_build_info A metric to report the version of the Kubernetes Monitoring Helm chart as well as a summary of enabled features
  # TYPE grafana_kubernetes_monitoring_build_info gauge
  grafana_kubernetes_monitoring_build_info{version="{{ .Chart.Version }}", namespace="{{ .Release.Namespace }}", features="{{ $features }}"} 1
{{- end }}
