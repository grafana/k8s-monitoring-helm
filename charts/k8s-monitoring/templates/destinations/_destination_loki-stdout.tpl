{{- define "destinations.loki-stdout.alloy" }}
{{- with .destination }}
otelcol.exporter.loki {{ include "helper.alloy_name" .name | quote }} {
  forward_to = [{{ include "destinations.loki-stdout.alloy.loki.logs.target" . }}]
}
{{- if .logProcessingRules }}

loki.relabel {{ include "helper.alloy_name" .name | quote }} {
{{ .logProcessingRules | indent 2 }}
  forward_to = [loki.echo.{{ include "helper.alloy_name" .name }}.receiver]
}
{{- end }}
{{- if .logProcessingStages }}

loki.process {{ include "helper.alloy_name" .name | quote }} {
{{ .logProcessingStages | indent 2 }}
  forward_to = [loki.echo.{{ include "helper.alloy_name" .name }}.receiver]
}
{{- end }}

loki.echo {{ include "helper.alloy_name" .name | quote }} {}
{{- end }}
{{- end }}

{{- define "secrets.list.loki-stdout" }}{{ end -}}

{{- define "destinations.loki-stdout.alloy.loki.logs.target" }}
  {{- if .logProcessingRules -}}
    loki.relabel.{{ include "helper.alloy_name" .name }}.receiver
  {{- else if .logProcessingStages -}}
    loki.process.{{ include "helper.alloy_name" .name }}.receiver
  {{- else -}}
    loki.echo.{{ include "helper.alloy_name" .name }}.receiver
  {{- end -}}
{{- end -}}
{{- define "destinations.loki-stdout.alloy.otlp.logs.target" }}otelcol.exporter.loki.{{ include "helper.alloy_name" .name }}.input{{ end -}}

{{- define "destinations.loki-stdout.supports_metrics" }}false{{ end -}}
{{- define "destinations.loki-stdout.supports_logs" }}true{{ end -}}
{{- define "destinations.loki-stdout.supports_traces" }}false{{ end -}}
{{- define "destinations.loki-stdout.supports_profiles" }}false{{ end -}}
{{- define "destinations.loki-stdout.ecosystem" }}loki{{ end -}}
