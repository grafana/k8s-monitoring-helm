{{/* Validates the top-level `dataProcessors:` map. Mirrors destinations.validate. */}}
{{- define "dataProcessors.validate" }}
{{- range $processorName, $processor := .Values.dataProcessors }}
  {{- if (regexFind "[^-_a-zA-Z0-9]" $processorName) }}
    {{- fail (printf "Invalid characters in processor name %q. Processor names must match `[-_a-zA-Z0-9]+`." $processorName) }}
  {{- end }}
  {{- if not $processor.type }}
    {{- fail (printf "Processor %q must have a `type` set." $processorName) }}
  {{- end }}
  {{- $types := (include "dataProcessors.types" .) | fromYamlArray }}
  {{- if not (has $processor.type $types) }}
    {{- fail (printf "Processor %q has unknown type %q. Known processor types: %v" $processorName $processor.type $types) }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Asserts that, for a given (type, ecosystem), every processor named in a feature's
     `dataProcessors:` list exists and supports that (type, ecosystem). Called from each
     feature that supports processors.

     Inputs:
       . (root)
       featureName (string)        — human-readable, for error messages
       processorNames ([]string)   — the feature's raw `processors:` list (pre-filter)
       type (string)
       ecosystem (string) */}}
{{- define "dataProcessors.validate.featureChain" }}
{{- range $procName := .processorNames }}
  {{- if not (hasKey $.Values.dataProcessors $procName) }}
    {{- fail (printf "Feature %q references processor %q which is not defined under `dataProcessors:`." $.featureName $procName) }}
  {{- end }}
  {{- $processor := get $.Values.dataProcessors $procName }}
  {{- $supports := include (printf "dataProcessors.%s.supports_%s_%s" $processor.type $.type $.ecosystem) $processor }}
  {{- if ne $supports "true" }}
    {{- fail (printf "Feature %q (type=%s, ecosystem=%s) requires processor %q to support that (type, ecosystem), but it does not." $.featureName $.type $.ecosystem $procName) }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Per-feature validation wrapper: validates the feature's dataProcessors chain for a
     (type, ecosystem). Reads the feature opt-in from .Values[featureKey].dataProcessors.

     Inputs: root (.), featureKey (string), featureName (string), type (string), ecosystem (string). */}}
{{- define "dataProcessors.validate.feature" }}
{{- $featureValues := default dict (get .root.Values .featureKey) }}
{{- $chain := default list (dig "dataProcessors" list $featureValues) }}
{{- include "dataProcessors.validate.featureChain" (dict "Values" .root.Values "featureName" .featureName "processorNames" $chain "type" .type "ecosystem" .ecosystem) }}
{{- end }}
