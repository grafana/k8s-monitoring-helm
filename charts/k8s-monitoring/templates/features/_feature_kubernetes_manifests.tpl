{{- define "features.kubernetesManifests.enabled" }}{{ .Values.kubernetesManifests.enabled }}{{- end }}

{{- define "features.kubernetesManifests.include" }}
{{- if .Values.kubernetesManifests.enabled -}}
{{- $destinations := include "features.kubernetesManifests.destinations" . | fromYamlArray }}
// Feature: Kubernetes Manifests
{{- include "feature.kubernetesManifests.module" (dict "Values" $.Values.kubernetesManifests "Files" $.Subcharts.kubernetesManifests.Files) }}
kubernetes_manifests "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "logs" "ecosystem" "loki") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.kubernetesManifests.destinations" }}
{{- if .Values.kubernetesManifests.enabled -}}
  {{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.kubernetesManifests.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.kubernetesManifests.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.kubernetesManifests.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "loki" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.kubernetesManifests.collector.values" }}{{- end -}}

{{- define "features.kubernetesManifests.chooseCollector" -}}{{- end -}}

{{- define "features.kubernetesManifests.validate" }}
{{- if .Values.kubernetesManifests.enabled -}}
{{- $featureKey := "kubernetesManifests" }}
{{- $featureName := "Kubernetes Manifests" }}
{{- $destinationNames := include "features.kubernetesManifests.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinationNames "type" "logs" "ecosystem" "loki" "featureName" $featureName) }}
{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- end -}}
{{- end -}}
