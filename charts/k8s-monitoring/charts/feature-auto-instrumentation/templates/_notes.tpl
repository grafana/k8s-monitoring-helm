{{- define "feature.autoInstrumentation.notes.deployments" }}
* Grafana Beyla (Daemonset)
{{- end }}

{{- define "feature.autoInstrumentation.notes.task" }}
Automatically instrument applications and services running in the cluster with Grafana Beyla
{{- end }}

{{- define "feature.autoInstrumentation.notes.actions" }}
{{- if and .Values.autoInstrumentation.enabled (not .Values.applicationObservability.enabled) }}

⚠️ Auto-Instrumentation (Beyla) is collecting span metrics, but traces are not being forwarded.
To collect full distributed traces from auto-instrumented applications, enable Application Observability:

applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true

Traces will automatically be sent to your OTLP receivers and forwarded to trace-capable destinations.
For more info: https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability
{{- end }}
{{- end }}

{{- define "feature.autoInstrumentation.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
