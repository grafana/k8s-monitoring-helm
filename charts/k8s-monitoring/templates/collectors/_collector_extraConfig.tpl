{{- define "collectors.extraConfig.alloy" -}}
  {{- if (index .Values .collectorName).extraConfig }}
{{ tpl (index .Values .collectorName).extraConfig $ | trim }}
  {{- end }}
{{- end -}}
