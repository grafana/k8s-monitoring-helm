{{- define "features.frontendObservability.enabled" }}{{ .Values.frontendObservability.enabled }}{{- end }}

{{- define "features.frontendObservability.collectors" }}
{{- if .Values.frontendObservability.enabled -}}
- {{ .Values.frontendObservability.collector }}
{{- end }}
{{- end }}

{{- define "features.frontendObservability.include" }}
{{- if .Values.frontendObservability.enabled -}}
{{- $destinations := include "features.frontendObservability.destinations" . | fromYamlArray }}

// Feature: Frontend Observability
{{- include "feature.frontendObservability.module" (dict "Values" $.Values.frontendObservability "Files" $.Subcharts.frontendObservability.Files) }}
frontend_observability "feature" {
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "faro") | indent 4 | trim }}
  ]
  traces_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "traces" "ecosystem" "faro") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.frontendObservability.destinations" }}
{{- if .Values.frontendObservability.enabled -}}
{{- $logDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "faro" "filter" $.Values.frontendObservability.destinations) | fromYamlArray -}}
{{- $traceDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "traces" "ecosystem" "faro" "filter" $.Values.frontendObservability.destinations) | fromYamlArray -}}
{{- concat $traceDestinations $logDestinations | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.frontendObservability.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.frontendObservability.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "faro" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.frontendObservability.collector.values" }}
{{- if .Values.frontendObservability.enabled -}}
{{- $values := dict }}
{{- range $collector := include "features.frontendObservability.collectors" . | fromYamlArray }}
  {{- $extraPorts := deepCopy (dig "alloy" "extraPorts" list (index $.Values $collector)) }}
  {{- if $.Values.frontendObservability.receivers.faro.enabled }}
    {{- if eq (include "collectors.has_extra_port" (deepCopy $ | merge (dict "name" $collector "portNumber" $.Values.frontendObservability.receivers.faro.port))) "false" }}
      {{- $extraPorts = append $extraPorts (dict "name" "faro" "port" $.Values.frontendObservability.receivers.faro.port "targetPort" $.Values.frontendObservability.receivers.faro.port "protocol" "TCP") }}
    {{- end -}}
  {{- end -}}

  {{- $values = $values | merge (dict $collector (dict "alloy" (dict "extraPorts" $extraPorts))) }}
{{- end -}}
{{- $values | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.frontendObservability.validate" }}
{{- if .Values.frontendObservability.enabled -}}
{{- $featureName := "Frontend Observability" }}

{{- range $collector := include "features.frontendObservability.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
  {{- if $.Values.frontendObservability.receivers.faro.enabled }}
    {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.frontendObservability.receivers.faro.port "portName" "faro" "portProtocol" "TCP") }}
  {{- end -}}
  {{- include "feature.frontendObservability.validate" (dict "Values" $.Values.frontendObservability) }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "features.frontendObservability.receiver.faro" }}
  {{- if and .Values.frontendObservability.enabled .Values.frontendObservability.receivers.faro.enabled }}
http://{{ include "collector.alloy.fullname" (deepCopy $ | merge (dict "collectorName" .Values.frontendObservability.collector)) }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.frontendObservability.receivers.faro.port }}
  {{- end }}
{{- end }}
