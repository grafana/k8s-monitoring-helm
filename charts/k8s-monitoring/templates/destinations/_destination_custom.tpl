{{- define "destinations.custom.alloy" }}
{{- with .destination }}

{{- if .metrics.enabled }}
{{- if eq .ecosystem "prometheus" }}
otelcol.exporter.prometheus {{ include "helper.alloy_name" $.destinationName | quote }} {
  forward_to = [{{ .metrics.target }}]
} // otelcol.exporter.prometheus "{{ include "helper.alloy_name" $.destinationName }}"
{{- else if eq .ecosystem "otlp" }}
otelcol.receiver.prometheus {{ include "helper.alloy_name" $.destinationName | quote }} {
  output {
    metrics = [{{ .metrics.target }}]
  }
} // otelcol.receiver.prometheus "{{ include "helper.alloy_name" $.destinationName }}"
{{- end }}
{{- end }}
{{- if .logs.enabled }}
{{- if eq .ecosystem "loki" }}
otelcol.exporter.loki {{ include "helper.alloy_name" $.destinationName | quote }} {
  forward_to = [{{ .logs.target }}]
} // otelcol.exporter.loki "{{ include "helper.alloy_name" $.destinationName }}"
{{- else if eq .ecosystem "otlp" }}
otelcol.receiver.loki {{ include "helper.alloy_name" $.destinationName | quote }} {
  output {
    logs = [{{ .logs.target }}]
  }
} // otelcol.receiver.loki "{{ include "helper.alloy_name" $.destinationName }}"
{{- end }}
{{- end }}
{{ .config | trim | nindent 0 }}
{{- end }}
{{- end }}

{{- define "secrets.list.custom" }}{{ end -}}

{{- /* Metrics handling */}}
{{- define "destinations.custom.supports_metrics" }}{{ dig "metrics" "enabled" "false" . }}{{ end -}}
{{- define "destinations.custom.alloy.prometheus.metrics.target" }}
{{- if eq .destination.ecosystem "prometheus" -}}
  {{- .destination.metrics.target }}
{{- else if eq .destination.ecosystem "otlp" -}}
  otelcol.receiver.prometheus.{{ include "helper.alloy_name" .destinationName }}.receiver
{{- end }}
{{- end }}
{{- define "destinations.custom.alloy.otlp.metrics.target" }}
{{- if eq .destination.ecosystem "prometheus" -}}
  otelcol.exporter.prometheus.{{ include "helper.alloy_name" .destinationName }}.receiver
{{- else if eq .destination.ecosystem "otlp" -}}
  {{- .destination.metrics.target }}
{{- end }}
{{- end }}

{{- /* Logs handling */}}
{{- define "destinations.custom.supports_logs" }}{{ dig "logs" "enabled" "false" . }}{{ end -}}
{{- define "destinations.custom.alloy.loki.logs.target" }}
{{- if eq .destination.ecosystem "loki" -}}
  {{- .destination.logs.target }}
{{- else if eq .destination.ecosystem "otlp" -}}
  otelcol.receiver.loki.{{ include "helper.alloy_name" $.destinationName }}.receiver
{{- end }}
{{- end }}
{{- define "destinations.custom.alloy.otlp.logs.target" }}
{{- if eq .destination.ecosystem "loki" -}}
  otelcol.exporter.loki.{{ include "helper.alloy_name" $.destinationName }}.receiver
{{- else if eq .destination.ecosystem "otlp" -}}
  {{- .destination.logs.target }}
{{- end }}
{{- end }}

{{- /* Traces handling */}}
{{- define "destinations.custom.supports_traces" }}{{ dig "traces" "enabled" "false" . }}{{ end -}}
{{- define "destinations.custom.alloy.otlp.traces.target" }}{{ .traces.target }}{{ end }}

{{- /* Profiles handling */}}
{{- define "destinations.custom.supports_profiles" }}{{ dig "profiles" "enabled" "false" . }}{{ end -}}
{{- define "destinations.custom.alloy.pyroscope.profiles.target" }}{{ .profiles.target }}{{ end }}

{{- define "destinations.custom.ecosystem" }}{{ .ecosystem }}{{ end -}}
