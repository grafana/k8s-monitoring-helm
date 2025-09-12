{{- define "features.privateDatasourceConnect.enabled" }}{{ .Values.privateDatasourceConnect.enabled }}{{- end }}

{{- define "features.privateDatasourceConnect.collectors" }}
{{- if .Values.privateDatasourceConnect.enabled -}}
- {{ .Values.privateDatasourceConnect.collector }}
{{- end }}
{{- end }}

{{- define "features.privateDatasourceConnect.include" }}
{{- if .Values.privateDatasourceConnect.enabled -}}
{{- $destinations := include "features.privateDatasourceConnect.destinations" . | fromYamlArray }}
// Feature: Private Datasource Connect (PDC Agent)
{{- include "feature.privateDatasourceConnect.module" (dict "Values" $.Values.privateDatasourceConnect "Files" $.Subcharts.privateDatasourceConnect.Files "Release" $.Release) }}
pdc_agent "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.privateDatasourceConnect.destinations" }}
{{- if .Values.privateDatasourceConnect.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.privateDatasourceConnect.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.privateDatasourceConnect.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.privateDatasourceConnect.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.privateDatasourceConnect.collector.values" }}{{- end -}}

{{- define "features.privateDatasourceConnect.validate" }}
{{- if .Values.privateDatasourceConnect.enabled -}}
{{- $featureName := "Private Datasource Connect" }}
{{- $destinations := include "features.privateDatasourceConnect.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
{{- range $collector := include "features.privateDatasourceConnect.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
{{- end -}}
{{- include "feature.privateDatasourceConnect.validate" (dict "Values" $.Values.privateDatasourceConnect) }}
{{- end -}}
{{- end -}}
