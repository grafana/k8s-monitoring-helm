{{- define "feature.podLogs.notes.deployments" }}{{- end }}

{{- define "feature.podLogs.notes.task" }}
Gather logs from Kubernetes Pods
{{- end }}

{{- define "feature.podLogs.notes.actions" }}{{- end }}

{{- define "feature.podLogs.notes.deprecations" }}
{{- if .Values.gatherMethod }}
* The `gatherMethod` value is deprecated and will be removed in a future release.
  Please enable the desired Pod log gathering methods individually:
    volumeGathering:
      enabled: true
    kubernetesApiStreaming:
      enabled: true
    lokiReceiver:
      enabled: true
{{- end }}
{{- end }}

{{- define "feature.podLogs.summary" -}}
{{- $methods := list }}
{{- if .Values.volumeGathering.enabled }}{{- $methods = append $methods "volumes" }}{{ end }}
{{- if .Values.kubernetesApiStreaming.enabled }}{{- $methods = append $methods "kubernetesApi" }}{{ end }}
{{- if .Values.lokiReceiver.enabled }}{{- $methods = append $methods "lokiReceiver" }}{{ end }}
{{- if .Values.openShiftClusterLogForwarder.enabled }}{{- $methods = append $methods "OSClusterLogForwarder" }}{{ end }}
version: {{ .Chart.Version }}
methods: {{ $methods | join "," }}
{{- end }}
