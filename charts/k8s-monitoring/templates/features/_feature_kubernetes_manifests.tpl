{{- define "features.kubernetesManifests.enabled" }}{{ .Values.kubernetesManifests.enabled }}{{- end }}

{{- define "features.kubernetesManifests.collectors" }}
{{- if .Values.kubernetesManifests.enabled -}}
- {{ .Values.kubernetesManifests.collector }}
{{- end }}
{{- end }}

{{- define "features.kubernetesManifests.include" }}
{{- if .Values.kubernetesManifests.enabled -}}
{{- $destinations := include "features.kubernetesManifests.destinations" . | fromYamlArray }}

// Feature: Kubernetes Manifests
{{- include "feature.kubernetesManifests.module" (dict "Values" .Values.kubernetesManifests "Files" $.Subcharts.kubernetesManifests.Files "Release" $.Release) }}
kubernetes_manifests "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "otlp") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.kubernetesManifests.destinations" }}
{{- if .Values.kubernetesManifests.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "otlp" "filter" $.Values.kubernetesManifests.destinations) -}}
{{- end -}}
{{- end -}}


{{- define "features.kubernetesManifests.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.kubernetesManifests.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "otlp" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.kubernetesManifests.collector.values" }}
{{- if .Values.kubernetesManifests.enabled -}}
{{- $values := dict }}
{{- range $collector := include "features.kubernetesManifests.collectors" . | fromYamlArray }}
  {{- $featureValues := dict "Values" $.Values.kubernetesManifests "Files" $.Subcharts.kubernetesManifests.Files "Release" $.Release "CollectorName" $collector }}
  {{- $extraContainers := include "feature.kubernetesManifests.sidecarContainer" $featureValues | fromYamlArray }}
  {{- $extraVolumes := include "feature.kubernetesManifests.volume" $featureValues | fromYamlArray }}
  {{- $extraVolumeMounts := include "feature.kubernetesManifests.volumeMount" $featureValues | fromYamlArray }}

  {{- $values = $values | merge (dict $collector (dict "alloy" (dict "mounts" (dict "extra" $extraVolumeMounts)) "controller" (dict "extraContainers" $extraContainers "volumes" (dict "extra" $extraVolumes)))) }}
{{- end -}}
{{- $values | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.kubernetesManifests.validate" }}
{{- if .Values.kubernetesManifests.enabled -}}
{{- $featureName := "Kubernetes Manifests" }}
{{- $destinations := include "features.kubernetesManifests.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "logs" "ecosystem" "otlp" "feature" $featureName) }}

{{- range $collectorName := include "features.kubernetesManifests.collectors" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (deepCopy $ | merge (dict "collectorName" $collectorName)) | fromYaml }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collectorName "feature" $featureName) }}
  {{- include "feature.kubernetesManifests.collector.validate" (dict "Values" $.Values.kubernetesManifests "Collector" $collectorValues "CollectorName" $collectorName) }}
{{- end -}}
{{- end -}}
{{- end -}}
