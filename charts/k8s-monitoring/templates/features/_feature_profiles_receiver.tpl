{{- define "features.profilesReceiver.enabled" }}{{ .Values.profilesReceiver.enabled }}{{- end }}

{{- define "features.profilesReceiver.collectors" }}
{{- if .Values.profilesReceiver.enabled -}}
- {{ .Values.profilesReceiver.collector }}
{{- end }}
{{- end }}

{{- define "features.profilesReceiver.include" }}
{{- if .Values.profilesReceiver.enabled -}}
{{- $destinations := include "features.profilesReceiver.destinations" . | fromYamlArray }}
// Feature: Profiles Receiver
{{- include "feature.profilesReceiver.module" (dict "Values" $.Values.profilesReceiver "Files" $.Subcharts.profilesReceiver.Files) }}
profiles_receiver "feature" {
  profiles_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "profiles" "ecosystem" "pyroscope") | indent 4 | trim }}
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
{{- range $collector := include "features.profilesReceiver.collectors" . | fromYamlArray }}
  {{- $extraPorts := deepCopy (dig "alloy" "extraPorts" list (index $.Values $collector)) }}
  {{- if eq (include "collectors.has_extra_port" (deepCopy $ | merge (dict "name" $collector "portNumber" $.Values.profilesReceiver.port))) "false" }}
    {{- $extraPorts = append $extraPorts (dict "name" "profiles" "port" $.Values.profilesReceiver.port "targetPort" $.Values.profilesReceiver.port "protocol" "TCP") }}
  {{- end -}}
  {{- $values = $values | merge (dict $collector (dict "alloy" (dict "extraPorts" $extraPorts))) }}
{{- end -}}
{{- $values | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.profilesReceiver.validate" }}
{{- if .Values.profilesReceiver.enabled -}}
{{- $featureName := "Profiles Receiver" }}
{{- $destinations := include "features.profilesReceiver.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "profiles" "ecosystem" "pyroscope" "feature" $featureName) }}
{{- range $collector := include "features.profilesReceiver.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
  {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.profilesReceiver.port "portName" "profiles" "portProtocol" "TCP") }}
{{- end -}}
{{- end -}}
{{- end -}}
