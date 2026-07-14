{{/* Print a no-op (null) destination's Alloy config components. */}}
{{/* Every component below is a dead-end: it accepts data for its signal and drops it. */}}
{{/* Inputs: . (root object), destination (map), destinationName (name of this destination) */}}
{{- define "destinations.nop.alloy" }}
{{- with .destination }}
{{- if .metrics.enabled }}
// DEAD-END: Prometheus-ecosystem metrics arrive here and are dropped.
// forward_to = [] means there are no downstream receivers, so every sample is discarded.
prometheus.relabel {{ include "helper.alloy_name" $.destinationName | quote }} {
  forward_to = []
} // prometheus.relabel "{{ include "helper.alloy_name" $.destinationName }}" (dead-end, drops all metrics)

// DEAD-END: OTLP-ecosystem metrics arrive here, are converted to Prometheus form, and dropped.
// forward_to = [] means the fanout has no receivers, so nothing is written anywhere.
otelcol.exporter.prometheus {{ include "helper.alloy_name" $.destinationName | quote }} {
  forward_to = []
} // otelcol.exporter.prometheus "{{ include "helper.alloy_name" $.destinationName }}" (dead-end, drops all metrics)
{{- end }}
{{- if .logs.enabled }}
// DEAD-END: Loki-ecosystem logs arrive here and are dropped.
// forward_to = [] means there are no downstream receivers, so every entry is discarded.
loki.relabel {{ include "helper.alloy_name" $.destinationName | quote }} {
  forward_to = []
} // loki.relabel "{{ include "helper.alloy_name" $.destinationName }}" (dead-end, drops all logs)

// DEAD-END: OTLP-ecosystem logs arrive here, are converted to Loki form, and dropped.
// forward_to = [] means the fanout has no receivers, so nothing is written anywhere.
otelcol.exporter.loki {{ include "helper.alloy_name" $.destinationName | quote }} {
  forward_to = []
} // otelcol.exporter.loki "{{ include "helper.alloy_name" $.destinationName }}" (dead-end, drops all logs)
{{- end }}
{{- if .traces.enabled }}
// DEAD-END: OTLP traces arrive here. All span-to-log conversion is disabled, and the
// empty output block has no consumers, so every trace is consumed and dropped.
otelcol.connector.spanlogs {{ include "helper.alloy_name" $.destinationName | quote }} {
  output { } // no consumers = all data dropped
} // otelcol.connector.spanlogs "{{ include "helper.alloy_name" $.destinationName }}" (dead-end, drops all traces)
{{- end }}
{{- if .profiles.enabled }}
// DEAD-END: profiles arrive here and are dropped.
// forward_to = [] means there are no downstream receivers, so every profile is discarded.
pyroscope.relabel {{ include "helper.alloy_name" $.destinationName | quote }} {
  forward_to = []
} // pyroscope.relabel "{{ include "helper.alloy_name" $.destinationName }}" (dead-end, drops all profiles)
{{- end }}
{{- end }}
{{- end }}

{{- define "secrets.list.nop" }}{{ end -}}

{{- define "destinations.nop.alloy.prometheus.metrics.target" }}prometheus.relabel.{{ include "helper.alloy_name" .destinationName }}.receiver{{ end -}}
{{- define "destinations.nop.alloy.otlp.metrics.target" }}otelcol.exporter.prometheus.{{ include "helper.alloy_name" .destinationName }}.input{{ end -}}
{{- define "destinations.nop.alloy.loki.logs.target" }}loki.relabel.{{ include "helper.alloy_name" .destinationName }}.receiver{{ end -}}
{{- define "destinations.nop.alloy.otlp.logs.target" }}otelcol.exporter.loki.{{ include "helper.alloy_name" .destinationName }}.input{{ end -}}
{{- define "destinations.nop.alloy.otlp.traces.target" }}otelcol.connector.spanlogs.{{ include "helper.alloy_name" .destinationName }}.input{{ end -}}
{{- define "destinations.nop.alloy.pyroscope.profiles.target" }}pyroscope.relabel.{{ include "helper.alloy_name" .destinationName }}.receiver{{ end -}}

{{- define "destinations.nop.supports_metrics" }}{{ dig "metrics" "enabled" "true" . }}{{ end -}}
{{- define "destinations.nop.supports_logs" }}{{ dig "logs" "enabled" "true" . }}{{ end -}}
{{- define "destinations.nop.supports_traces" }}{{ dig "traces" "enabled" "true" . }}{{ end -}}
{{- define "destinations.nop.supports_profiles" }}{{ dig "profiles" "enabled" "true" . }}{{ end -}}
{{- define "destinations.nop.ecosystem" }}nop{{ end -}}
