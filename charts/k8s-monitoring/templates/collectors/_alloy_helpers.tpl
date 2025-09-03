{{- define "collectors.alloy.get_all_names" -}}
{{- $alloyNames := list }}
{{/* Standard Alloy collectors */}}
{{- range $collectorName := (include "collectors.list.enabled" . | fromYamlArray) }}
  {{- $values := (deepCopy $ | merge (dict "collectorName" $collectorName)) }}
  {{- $alloyNames = append $alloyNames (include "collector.alloy.fullname" $values) }}
{{- end }}

{{- range $destination := .Values.destinations }}
  {{- if eq $destination.type "otlp" }}
    {{/* Tail sampling Alloy instances */}}
    {{- if eq (include "destinations.otlp.isTailSamplingEnabled" $destination) "true" }}
      {{- $maxLength := 51 }}{{/* This limit is from the `controller-revision-hash` pod label value*/}}
      {{- $collectorName := printf "%s-%s" $.Release.Name (include "helper.k8s_name" (printf "%s-sampler" $destination.name)) | trunc $maxLength | trimSuffix "-" | lower }}
      {{- $alloyNames = append $alloyNames $collectorName }}
    {{- end }}
    {{/* Service graph metrics Alloy instances */}}
    {{- if eq (include "destinations.otlp.isServiceGraphsEnabled" $destination) "true" }}
      {{- $maxLength := 51 }}{{/* This limit is from the `controller-revision-hash` pod label value*/}}
      {{- $collectorName := printf "%s-%s" $.Release.Name (include "helper.k8s_name" (printf "%s-servicegraph" $destination.name)) | trunc $maxLength | trimSuffix "-" | lower }}
      {{- $alloyNames = append $alloyNames $collectorName }}
    {{- end }}
  {{- end }}
{{- end }}
{{ $alloyNames | sortAlpha | toYaml }}
{{- end }}
