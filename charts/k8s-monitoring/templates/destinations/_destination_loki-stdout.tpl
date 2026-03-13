{{/* Print a Loki Stdout destination Alloy config components */}}
{{/* Inputs: . (root object),  destination (string, name of destination), destinationName (name of this destination) */}}
{{- define "destinations.loki-stdout.alloy" }}
{{- with .destination }}
otelcol.exporter.loki {{ include "helper.alloy_name" $.destinationName | quote }} {
  forward_to = [{{ include "destinations.loki-stdout.alloy.loki.logs.target" $ }}]
}
{{- if .logProcessingRules }}

loki.relabel {{ include "helper.alloy_name" $.destinationName | quote }} {
{{ .logProcessingRules | indent 2 }}
  forward_to = [loki.echo.{{ include "helper.alloy_name" $.destinationName }}.receiver]
}
{{- end }}
{{- if .logProcessingStages }}

loki.process {{ include "helper.alloy_name" $.destinationName | quote }} {
{{ .logProcessingStages | indent 2 }}
  forward_to = [loki.echo.{{ include "helper.alloy_name" $.destinationName }}.receiver]
}
{{- end }}

loki.echo {{ include "helper.alloy_name" $.destinationName | quote }} {}
{{- end }}
{{- end }}

{{- define "secrets.list.loki-stdout" }}{{ end -}}

{{- define "destinations.loki-stdout.alloy.loki.logs.target" }}
{{- if .destination.logProcessingRules -}}
loki.relabel.{{ include "helper.alloy_name" .destinationName }}.receiver
{{- else if .destination.logProcessingStages -}}
loki.process.{{ include "helper.alloy_name" .destinationName }}.receiver
{{- else -}}
loki.echo.{{ include "helper.alloy_name" .destinationName }}.receiver
{{- end -}}
{{- end }}
{{- define "destinations.loki-stdout.alloy.otlp.logs.target" }}otelcol.exporter.loki.{{ include "helper.alloy_name" .destinationName }}.input{{ end -}}

{{- define "destinations.loki-stdout.supports_metrics" }}false{{ end -}}
{{- define "destinations.loki-stdout.supports_logs" }}true{{ end -}}
{{- define "destinations.loki-stdout.supports_traces" }}false{{ end -}}
{{- define "destinations.loki-stdout.supports_profiles" }}false{{ end -}}
{{- define "destinations.loki-stdout.ecosystem" }}loki{{ end -}}
