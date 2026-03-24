{{- define "features.profilesReceiver.enabled" }}{{ .Values.profilesReceiver.enabled }}{{- end }}

{{- define "features.profilesReceiver.include" }}
{{- if .Values.profilesReceiver.enabled -}}
{{- $destinations := include "features.profilesReceiver.destinations" . | fromYamlArray }}
// Feature: Profiles Receiver
{{- include "feature.profilesReceiver.module" (dict "Values" $.Values.profilesReceiver "Files" $.Subcharts.profilesReceiver.Files) }}
profiles_receiver "feature" {
  profiles_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "profiles" "ecosystem" "pyroscope") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.profilesReceiver.destinations" }}
{{- if .Values.profilesReceiver.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "profiles" "ecosystem" "pyroscope" "filter" $.Values.profilesReceiver.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.profilesReceiver.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.profilesReceiver.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "pyroscope" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.profilesReceiver.collector.values" }}
{{- if .Values.profilesReceiver.enabled -}}
  {{- $values := dict }}
  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" "profilesReceiver") }}
  {{- $collectorValues := (include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml) }}
  {{- $extraPorts := deepCopy (dig "alloy" "extraPorts" list $collectorValues) }}
  {{- if eq (include "collectors.hasExtraPort" (deepCopy $ | merge (dict "collectorName" $collectorName "portNumber" $.Values.profilesReceiver.port))) "false" }}
    {{- $extraPorts = append $extraPorts (dict "name" "profiles" "port" $.Values.profilesReceiver.port "targetPort" $.Values.profilesReceiver.port "protocol" "TCP") }}
  {{- end -}}
  {{- $values = $values | merge (dict "collectors" (dict $collectorName (dict "alloy" (dict "extraPorts" $extraPorts)))) }}
{{- $values | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.profilesReceiver.chooseCollector" -}}{{- end -}}

{{- define "features.profilesReceiver.validate" }}
{{- if .Values.profilesReceiver.enabled -}}
{{- $featureKey := "profilesReceiver" }}
{{- $featureName := "Profiles Receiver" }}
{{- $destinations := include "features.profilesReceiver.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "profiles" "ecosystem" "pyroscope" "featureName" $featureName) }}
{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- include "collectors.requireExtraPort" (dict "Values" $.Values "collectorName" $collectorName "featureName" $featureName "portNumber" $.Values.profilesReceiver.port "portName" "profiles" "portProtocol" "TCP") }}
{{- end -}}
{{- end -}}
