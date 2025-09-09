{{- define "destinations.custom.alloy" }}
{{- with .destination }}

{{- if .metrics.enabled }}
{{- if eq .ecosystem "prometheus" }}
otelcol.exporter.prometheus {{ include "helper.alloy_name" .name | quote }} {
  forward_to = [{{ .metrics.target }}]
}
{{- else if eq .ecosystem "otlp" }}
otelcol.receiver.prometheus {{ include "helper.alloy_name" .name | quote }} {
  output {
    metrics = [{{ .metrics.target }}]
  }
}
{{- end }}
{{- end }}
{{- if .logs.enabled }}
{{- if eq .ecosystem "loki" }}
otelcol.exporter.loki {{ include "helper.alloy_name" .name | quote }} {
  forward_to = [{{ .logs.target }}]
}
{{- else if eq .ecosystem "otlp" }}
otelcol.receiver.loki {{ include "helper.alloy_name" .name | quote }} {
  output {
    logs = [{{ .logs.target }}]
  }
}
{{- end }}
{{- end }}
{{ .config | trim | nindent 0 }}
{{- end }}
{{- end }}

{{- define "secrets.list.custom" }}{{ end -}}

{{- /* Metrics handling */}}
{{- define "destinations.custom.supports_metrics" }}{{ dig "metrics" "enabled" "false" . }}{{ end -}}
{{- define "destinations.custom.alloy.prometheus.metrics.target" }}
{{- if eq .ecosystem "prometheus" -}}
  {{- .metrics.target }}
{{- else if eq .ecosystem "otlp" -}}
  otelcol.receiver.prometheus.{{ include "helper.alloy_name" .name }}.receiver
{{- end }}
{{- end }}
{{- define "destinations.custom.alloy.otlp.metrics.target" }}
{{- if eq .ecosystem "prometheus" -}}
  otelcol.exporter.prometheus.{{ include "helper.alloy_name" .name }}.receiver
{{- else if eq .ecosystem "otlp" -}}
  {{- .metrics.target }}
{{- end }}
{{- end }}

{{- /* Logs handling */}}
{{- define "destinations.custom.supports_logs" }}{{ dig "logs" "enabled" "false" . }}{{ end -}}
{{- define "destinations.custom.alloy.loki.logs.target" }}
{{- if eq .ecosystem "loki" -}}
  {{- .logs.target }}
{{- else if eq .ecosystem "otlp" -}}
  otelcol.receiver.loki.{{ include "helper.alloy_name" .name }}.receiver
{{- end }}
{{- end }}
{{- define "destinations.custom.alloy.otlp.logs.target" }}
{{- if eq .ecosystem "loki" -}}
  otelcol.exporter.loki.{{ include "helper.alloy_name" .name }}.receiver
{{- else if eq .ecosystem "otlp" -}}
  {{- .logs.target }}
{{- end }}
{{- end }}

{{- /* Traces handling */}}
{{- define "destinations.custom.supports_traces" }}{{ dig "traces" "enabled" "false" . }}{{ end -}}
{{- define "destinations.custom.alloy.otlp.traces.target" }}{{ .traces.target }}{{ end }}

{{- /* Profiles handling */}}
{{- define "destinations.custom.supports_profiles" }}{{ dig "profiles" "enabled" "false" . }}{{ end -}}
{{- define "destinations.custom.alloy.pyroscope.profiles.target" }}{{ .profiles.target }}{{ end }}

{{- define "destinations.custom.ecosystem" }}{{ .ecosystem }}{{ end -}}
