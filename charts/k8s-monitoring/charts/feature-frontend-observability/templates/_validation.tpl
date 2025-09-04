{{- define "feature.applicationObservability.validate" }}
{{- $aRecevierIsEnabled := or .Values.receivers.otlp.grpc.enabled .Values.receivers.otlp.http.enabled }}
{{- $aRecevierIsEnabled = or $aRecevierIsEnabled .Values.receivers.zipkin.enabled }}
{{- $aRecevierIsEnabled = or $aRecevierIsEnabled .Values.receivers.jaeger.grpc.enabled .Values.receivers.jaeger.thriftBinary.enabled .Values.receivers.jaeger.thriftCompact.enabled .Values.receivers.jaeger.thriftHttp.enabled }}
{{- if not $aRecevierIsEnabled }}
  {{- $msg := list "" "At least one receiver must be enabled to use Application Observability." }}
  {{- $msg = append $msg "Please enable one. For example:" }}
  {{- $msg = append $msg "applicationObservability:" }}
  {{- $msg = append $msg "  receivers:" }}
  {{- $msg = append $msg "    otlp:" }}
  {{- $msg = append $msg "      grpc:" }}
  {{- $msg = append $msg "        enabled: true" }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
