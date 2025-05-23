{{/*
  Takes a list of strings and returns a new list where each element is quoted
*/}}
{{- define "policy.quoteAll" -}}
{{- $quoted := list -}}
{{- range . }}
  {{- $quoted = append $quoted (printf "%q" .) -}}
{{- end }}
{{- join ", " $quoted -}}
{{- end }}

{{- define "policy.generate" }}
{{- $policy := . -}}
{{- if eq $policy.type "always_sample" -}}
{{- /*NOOP*/ -}}
{{- else if eq $policy.type "latency" }}
latency {
  threshold_ms = {{ $policy.threshold_ms }}
  {{- if hasKey $policy "upper_threshold_ms" }}
  upper_threshold_ms = {{ $policy.upper_threshold_ms }}
  {{- end }}
}
{{- else if eq $policy.type "numeric_attribute" }}
numeric_attribute {
  key = {{ $policy.key | quote }}
  min_value = {{ $policy.min_value }}
  {{- if hasKey $policy "max_value" }}
  max_value = {{ $policy.max_value }}
  {{ end }}
}
{{- else if eq $policy.type "probabilistic" }}
probabilistic {
  sampling_percentage = {{ $policy.sampling_percentage }}
}{{/*TODO additional config params*/}}
{{- else if eq $policy.type "status_code" }}
status_code {
  status_codes = [
  {{- range $index, $code := $policy.status_codes }}
    {{- if $index }}, {{ end }}{{ $code | quote }}
  {{- end -}}
  ]
}
{{- else if eq $policy.type "string_attribute" }}
string_attribute {
  key = {{ $policy.key | quote }}
  values = [
  {{- range $index, $value := $policy.values }}
    {{- if $index }}, {{ end }}{{ $value | quote }}
  {{- end -}}
  ]
}{{/*TODO additional config params*/}}
{{- else if eq $policy.type "trace_state" }}
trace_state {
  key = {{ $policy.key | quote }}
  values = [
  {{- range $index, $value := $policy.values }}
    {{- if $index }}, {{ end }}{{ $value | quote }}
  {{- end -}}
  ]
}
{{- else if eq $policy.type "rate_limiting" }}
rate_limiting {
  spans_per_second = {{ $policy.spans_per_second }}
}
{{- else if eq $policy.type "span_count" }}
span_count {
  min_spans = {{ $policy.min_spans }}
  {{- if hasKey $policy "max_spans" }}
  max_spans = {{ $policy.max_spans }}
  {{ end }}
}
{{- else if eq $policy.type "boolean_attribute" }}
boolean_attribute {
  key = {{ $policy.key | quote }}
  value = {{ $policy.value }}
  {{- if hasKey $policy "invert_match" }}
  invert_match = {{ $policy.invert_match }}
  {{- end }}
}
{{- else if eq $policy.type "ottl_condition" }}
ottl_condition {
  error_mode = {{ $policy.error_mode | quote }}
  {{- if hasKey $policy "span" }}
  span = [
  {{- range $index, $condition := $policy.span}}
    {{- if $index }}, {{ end }}{{ $condition | quote }}
  {{- end -}}
  ]
  {{- end }}
  {{- if hasKey $policy "spanevent" }}
  spanevent = [
  {{- range $index, $condition:= $policy.spanevent}}
    {{- if $index }}, {{ end }}{{ $condition | quote }}
  {{- end }}
  ]
  {{- end }}
}
{{- else }}
{{ fail (printf "invalid policy type: %s" $policy.type) }}
{{- end }}
{{- end }}
