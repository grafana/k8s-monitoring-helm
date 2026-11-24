{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{- define "feature.applicationObservability.processor.memory_limiter.alloy.target" }}otelcol.processor.memory_limiter.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.memory_limiter.alloy" }}
{{- $memoryLimiter := .Values.processors.memoryLimiter }}
{{- $limit := toString ($memoryLimiter.limit | default "") | trim }}
{{- $hasLimit := and $limit (not (regexMatch "^0+(\\.0*)?\\s*[a-zA-Z]*$" $limit)) }}
{{- $limitPercentage := $memoryLimiter.limitPercentage | default 0 | int }}
{{- $spikeLimitPercentage := $memoryLimiter.spikeLimitPercentage | default 0 | int }}
{{- if not $hasLimit }}
  {{- if or (le $limitPercentage 0) (gt $limitPercentage 100) }}
    {{- $msg := list "" (printf "The memory limiter processor limitPercentage (%d) must be between 1 and 100, or a fixed limit must be set." $limitPercentage) }}
    {{- $msg = append $msg "For example:" }}
    {{- $msg = append $msg "applicationObservability:" }}
    {{- $msg = append $msg "  processors:" }}
    {{- $msg = append $msg "    memoryLimiter:" }}
    {{- $msg = append $msg "      enabled: true" }}
    {{- $msg = append $msg "      limit: 512MiB" }}
    {{- $msg = append $msg "Or:" }}
    {{- $msg = append $msg "      limitPercentage: 80" }}
    {{- $msg = append $msg "      spikeLimitPercentage: 20" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
  {{- if or (le $spikeLimitPercentage 0) (ge $spikeLimitPercentage $limitPercentage) }}
    {{- $msg := list "" (printf "The memory limiter processor spikeLimitPercentage (%d) must be at least 1 and less than limitPercentage (%d)." $spikeLimitPercentage $limitPercentage) }}
    {{- $msg = append $msg "For example:" }}
    {{- $msg = append $msg "applicationObservability:" }}
    {{- $msg = append $msg "  processors:" }}
    {{- $msg = append $msg "    memoryLimiter:" }}
    {{- $msg = append $msg "      enabled: true" }}
    {{- $msg = append $msg "      limitPercentage: 80" }}
    {{- $msg = append $msg "      spikeLimitPercentage: 20" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
otelcol.processor.memory_limiter "{{ .name | default "default" }}" {
  check_interval = {{ $memoryLimiter.checkInterval | quote }}
{{- if $hasLimit }}
  limit = {{ $limit | quote }}
{{- else }}
  limit_percentage = {{ $limitPercentage }}
  spike_limit_percentage = {{ $spikeLimitPercentage }}
{{- end }}

  output {
{{- if and .metrics .Values.metrics.enabled }}
    metrics = {{ .metrics }}
{{- end }}
{{- if and .logs .Values.logs.enabled }}
    logs = {{ .logs }}
{{- end }}
{{- if and .traces .Values.traces.enabled }}
    traces = {{ .traces }}
{{- end }}
  }
}
{{- end }}
