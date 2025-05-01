{{- define "sampler.processor.tail_sampling" -}}
otelcol.processor.tail_sampling "sampler" {
  // https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.tail_sampling/

  decision_wait = {{ .decision_wait | quote }}

  {{/* range .policies }}
    {{- include "policy.block" . | nindent 2 }}
  {{- end */}}

  output {
    traces = [otelcol.processor.batch.default.input]
  }
}
{{ end }}
