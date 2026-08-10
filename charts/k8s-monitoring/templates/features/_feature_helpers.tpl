{{- define "features.list" }}
- annotationAutodiscovery
- applicationObservability
- autoInstrumentation
- clusterMetrics
- clusterEvents
- costMetrics
- hostMetrics_linuxHosts
- hostMetrics_windowsHosts
- hostMetrics_energyMetrics
- integrations
- kubernetesManifests
- nodeLogs
- windowsEventLogs
- podLogsViaLoki
- podLogsViaOpenTelemetry
- podLogsViaKubernetesApi
- podLogsObjects
- profilesReceiver
- profiling
- prometheusOperatorObjects
- selfReporting
{{- end }}

{{- define "features.subchartName" }}
{{- first (regexSplit "_" . -1) }}
{{- end }}

{{- define "features.subfeatureName" }}
{{- last (regexSplit "_" . -1) }}
{{- end }}

{{- define "features.list.enabled" }}
{{- range $feature := ((include "features.list" .) | fromYamlArray ) }}
  {{- if eq (include (printf "features.%s.enabled" $feature) $) "true" }}
- {{ $feature }}
  {{- end }}
{{- end }}
{{- end }}
