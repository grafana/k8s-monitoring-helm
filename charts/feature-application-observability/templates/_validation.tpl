{{- define "feature.applicationObservability.validate" }}
{{- $aRecevierIsEnabled := or .Values.receivers.grpc.enabled .Values.receivers.http.enabled .Values.receivers.zipkin.enabled }}
{{- if not $aRecevierIsEnabled }}
  {{- $msg := list "" "At least one receiver must be enabled to use Application Observability." }}
  {{- $msg = append $msg "Please enable one. For example:" }}
  {{- $msg = append $msg "applicationObservability:" }}
  {{- $msg = append $msg "  receivers:" }}
  {{- $msg = append $msg "    grpc:" }}
  {{- $msg = append $msg "      enabled: true" }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/feature-application-observability for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
