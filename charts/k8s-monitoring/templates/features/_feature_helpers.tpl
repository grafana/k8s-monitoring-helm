{{- define "features.list" }}
- annotationAutodiscovery
- applicationObservability
- autoInstrumentation
- clusterMetrics
- clusterEvents
- nodeLogs
- podLogs
- profiling
- prometheusOperatorObjects
- integrations
- selfReporting
{{- end }}

{{- define "features.list.enabled" }}
{{- range $feature := ((include "features.list" .) | fromYamlArray ) }}
  {{- if eq (include (printf "features.%s.enabled" $feature) $) "true" }}
- {{ $feature }}
  {{- end }}
{{- end }}
{{- end }}
