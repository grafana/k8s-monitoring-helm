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

{{/* Renders chart-owned components that are shared across all of a processor's pipeline
     slices on a collector (e.g. a Kubernetes discovery used by every (type, ecosystem)
     slice). Called once per collector after the feature modules and pipeline slices are
     assembled; `config` is the assembled Alloy config so each processor type's hook can
     render its shared components only when something in the config references them.

     Inputs:
       Values (map)    — chart values (for .Values.dataProcessors)
       config (string) — the collector's assembled Alloy config */}}
{{- define "dataProcessors.alloy.collectorComponents" }}
{{- $types := include "dataProcessors.types" . | fromYamlArray }}
{{- range $processorName, $processor := default dict .Values.dataProcessors }}
  {{- if has $processor.type $types }}
    {{- include (printf "dataProcessors.%s.alloy.collectorComponents" $processor.type) (dict "processor" $processor "processorName" $processorName "config" $.config) }}
  {{- end }}
{{- end }}
{{- end }}