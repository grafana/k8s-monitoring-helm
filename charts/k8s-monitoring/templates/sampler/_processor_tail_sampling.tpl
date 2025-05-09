{{- define "sampler.processor.tailSampling.alloy.target" }}otelcol.processor.tail_sampling.{{ .name | default "default" }}.input{{ end }}
{{- define "sampler.processor.tailSampling.alloy" }}
otelcol.processor.tail_sampling {{ .name | default "default" | quote }} {
  // https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.tail_sampling/

  decision_wait = {{ .decisionWait | quote }}

{{- range .policies }}
{{ include "policy.block" . | trim | nindent 2 }}
{{- end }}

  output {
    traces = [{{ .traces }}]
  }
}
{{ end }}
