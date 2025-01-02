{{ define "feature.prometheusOperatorObjects.validate" -}}
{{ if and (not .Values.podMonitors.enabled) (not .Values.probes.enabled) (not .Values.serviceMonitors.enabled) }}
  {{- $msg := list "" "At least one of ServiceMonitors, PodMonitors, or Probes must be enabled. For example" }}
  {{- $msg = append $msg "prometheusOperatorObjects:" }}
  {{- $msg = append $msg "  serviceMonitors:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
