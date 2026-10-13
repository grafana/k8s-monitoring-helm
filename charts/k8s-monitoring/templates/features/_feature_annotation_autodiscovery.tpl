{{- define "features.annotationAutodiscovery.enabled" }}{{ .Values.annotationAutodiscovery.enabled }}{{- end }}

{{- define "features.annotationAutodiscovery.include" }}
{{- if .Values.annotationAutodiscovery.enabled -}}
{{- $destinations := include "features.annotationAutodiscovery.destinations" . | fromYamlArray }}
// Feature: Annotation Autodiscovery
{{- include "feature.annotationAutodiscovery.module" .Subcharts.annotationAutodiscovery }}
annotation_autodiscovery "feature" {
  metrics_destinations = [
    {{ include "dataProcessors.pipeline.targets.forFeature" (dict "root" $ "featureKey" "annotationAutodiscovery" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- include "dataProcessors.pipeline.render.forFeature" (dict "root" $ "featureKey" "annotationAutodiscovery" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end -}}
{{- end -}}

{{- define "features.annotationAutodiscovery.destinations" }}
{{- if .Values.annotationAutodiscovery.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.annotationAutodiscovery.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.annotationAutodiscovery.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.annotationAutodiscovery.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.annotationAutodiscovery.collector.values" }}{{- end -}}

{{- define "features.annotationAutodiscovery.validate" }}
{{- if .Values.annotationAutodiscovery.enabled -}}
  {{- $featureKey := "annotationAutodiscovery" }}
  {{- $featureName := "Annotation Autodiscovery" }}

  {{- $destinations := include "features.annotationAutodiscovery.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName "Values" $.Values "featureKey" $featureKey) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "annotationAutodiscovery" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
  {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}

  {{- include "feature.annotationAutodiscovery.validate" (dict "Values" $.Values.annotationAutodiscovery) }}
{{- end -}}
{{- end -}}

{{- define "features.annotationAutodiscovery.rbac" }}
{{- $entries := list }}
{{- $v := .Values.annotationAutodiscovery }}
{{- if $v.enabled }}
  {{- $namespaces := list }}
  {{- if and $v.namespaces (ne (include "feature.annotationAutodiscovery.namespaces.hasRegex" $v.namespaces) "true") }}
    {{- $namespaces = $v.namespaces }}
  {{- end }}
  {{- if $v.pods.enabled }}
    {{- $entries = append $entries (dict "bundle" "pods" "namespaces" $namespaces) }}
    {{- if eq (include "collectors.rbac.anyEnabled" $v.nodeLabels) "true" }}
      {{- $entries = append $entries (dict "bundle" "nodes") }}
    {{- end }}
  {{- end }}
  {{- if $v.services.enabled }}
    {{- $entries = append $entries (dict "bundle" "services" "namespaces" $namespaces) }}
  {{- end }}
  {{- if $v.attachNamespaceMetadata }}
    {{- $entries = append $entries (dict "bundle" "namespaces") }}
  {{- end }}
  {{- if $v.bearerToken.enabled }}
    {{- $entries = append $entries (dict "bundle" "metricsEndpoint") }}
  {{- end }}
{{- end }}
{{- $entries | toYaml }}
{{- end }}
