{{/* Resolves a feature's `dataProcessors:` list against the global dataProcessors map.

     Unlike `destinations.get`, this helper does NOT auto-match by ecosystem — a feature must
     name the dataProcessors it wants, in chain order. Names that don't exist or that don't support
     the requested (type, ecosystem) are dropped here; the validator surfaces those as errors
     before rendering.

     Inputs:
       dataProcessors (map)         — .Values.dataProcessors
       chosen ([]string)            — feature's `dataProcessors:` list, in chain order
       type (string)                — metrics | logs | traces | profiles
       ecosystem (string)           — prometheus | otlp | loki | pyroscope
     Output: YAML array of processor names (chain order preserved). */}}
{{- define "dataProcessors.get" }}
{{- $matches := list }}
{{- range $procName := .chosen }}
  {{- if hasKey $.dataProcessors $procName }}
    {{- $processor := get $.dataProcessors $procName }}
    {{- if eq (include (printf "dataProcessors.%s.supports_%s_%s" $processor.type $.type $.ecosystem) $processor) "true" }}
      {{- $matches = append $matches $procName }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if not (empty $matches) }}
  {{- $matches | toYaml | indent 0 }}
{{- end }}
{{- end }}