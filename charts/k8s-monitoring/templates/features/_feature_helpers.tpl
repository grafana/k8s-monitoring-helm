{{- define "features.list" }}
- annotationAutodiscovery
- applicationObservability
- autoInstrumentation
- clusterMetrics
- clusterEvents
- costMetrics
- hostMetrics
- integrations
- kubernetesManifests
- nodeLogs
- podLogsViaLoki
- podLogsViaOpenTelemetry
- podLogsViaKubernetesApi
- podLogsObjects
- profilesReceiver
- profiling
- prometheusOperatorObjects
- selfReporting
{{- end }}

{{- define "features.list.enabled" }}
{{- range $feature := ((include "features.list" .) | fromYamlArray ) }}
  {{- if eq (include (printf "features.%s.enabled" $feature) $) "true" }}
- {{ $feature }}
  {{- end }}
{{- end }}
{{- end }}
