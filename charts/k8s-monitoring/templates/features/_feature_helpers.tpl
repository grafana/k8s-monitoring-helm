{{- define "features.list" }}
- annotationAutodiscovery
- applicationObservability
- clusterMetrics
- clusterEvents
- podLogs
- profiling
- prometheusOperatorObjects
- integrations
- selfReporting
{{- end }}

{{- define "features.list.enabled" }}
{{- range $feature := ((include "features.list" .) | fromYamlArray ) }}
  {{- if eq (include (printf "features.%s.enabled" $feature) (dict "Values" $.Values)) "true" }}
- {{ $feature }}
  {{- end }}
{{- end }}
{{- end }}
