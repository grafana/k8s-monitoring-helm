{{- define "collectors.extraConfig.alloy" -}}
  {{- if (index .Values .collectorName).extraConfig }}
{{ (index .Values .collectorName).extraConfig | trim }}
  {{- end }}
{{- end -}}
