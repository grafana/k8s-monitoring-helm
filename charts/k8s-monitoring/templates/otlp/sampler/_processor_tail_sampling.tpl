{{- define "sampler.processor.tailSampling.alloy.target" }}otelcol.processor.tail_sampling.{{ .name | default "default" }}.input{{ end }}
{{- define "sampler.processor.tailSampling.alloy" }}
otelcol.processor.tail_sampling {{ .name | default "default" | quote }} {
  // https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.tail_sampling/

  decision_wait = {{ .decisionWait | quote }}
{{- if .decisionCache }}
  decision_cache = {
    sampled_cache_size     = {{ .decisionCache.sampledCacheSize }},
    non_sampled_cache_size = {{ .decisionCache.nonSampledCacheSize }},
  }
{{- end }}
{{- if .numTraces }}
  num_traces = {{ .numTraces }}
{{- end }}
{{- if .expectedNewTracesPerSec }}
  expected_new_traces_per_sec = {{ .expectedNewTracesPerSec }}
{{- end }}
{{- range .policies }}
{{ include "policy.block" . | trim | nindent 2 }}
{{- end }}

  output {
    traces = [{{ .traces }}]
  }
}
{{ end }}
