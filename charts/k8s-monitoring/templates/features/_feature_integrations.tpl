{{- define "features.integrations.enabled" }}
{{- /* Check if any integration type has instances configured and metrics/logs enabled */ -}}
{{- $hasMetrics := false }}
{{- $hasLogs := false }}
{{- range $key, $value := .Values }}
  {{- if and (kindIs "map" $value) (hasKey $value "instances") }}
    {{- if not (empty $value.instances) }}
      {{- if hasKey $value "metrics" }}
        {{- if $value.metrics.enabled }}
          {{- $hasMetrics = true }}
        {{- end }}
      {{- end }}
      {{- if hasKey $value "logs" }}
        {{- if $value.logs.enabled }}
          {{- $hasLogs = true }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if or $hasMetrics $hasLogs }}true{{ else }}false{{ end }}
{{- end }}

{{- define "features.integrations.collectors" }}
{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations) | fromYamlArray }}
{{- if (not (empty $metricIntegrations)) }}
- {{ .Values.integrations.collector }}
{{- end }}
{{- end }}

{{- define "features.integrations.metrics.include" }}
{{- $integrations := list }}
{{/* Get the Files object from the integrations subchart */}}
{{/* Iterate over each integration type defined in the chart */}}
{{/* We use the "integrations.types" template to get a list of all possible integration types */}}
{{- range $type := (include "integrations.types" .) | fromYamlArray }}
  {{/* Check if the current integration type is configured in the values */}}
  {{- if hasKey $.Values.integrations $type }}
    {{- with (index $.Values.integrations $type) }}
      {{/* Ensure the integration has instances configured and is a map */}}
      {{- if and (kindIs "map" .) (hasKey . "instances") (not (empty .instances)) }}
        {{/* Check if the integration type has metrics enabled */}}
        {{- if eq (include (printf "integrations.%s.type.metrics" $type) $) "true" }}
          {{/* Add the integration type to the list of integrations to include */}}
          {{- $integrations = append $integrations $type }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* If there are any integrations to include, process them */}}
{{- if $integrations }}
  {{/* This is necessary to access any additional configuration files that might be needed for integrations */}}
  {{- $integrationsFiles := .Subcharts.integrations.Files }}
  {{- range $integration := $integrations }}
    {{/* Create a new context for each integration while preserving all original context fields */}}
    {{/* This ensures that each integration has access to its specific configuration and the global context */}}
    {{- $newValues := deepCopy $.Values }}
    {{- $_ := set $newValues $integration (index $.Values.integrations $integration) }}
    {{- $ctx := dict "Values" $newValues "Files" $integrationsFiles "Release" $.Release "Chart" $.Chart "Template" $.Template }}
    {{/* Include the metrics module for the current integration type */}}
    {{/* This dynamically calls the appropriate template for the integration's metrics configuration */}}
    {{- include (printf "integrations.%s.module.metrics" $integration) $ctx }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "features.integrations.include" }}
{{- if eq .collectorName .Values.integrations.collector }}
  {{ include "features.integrations.metrics.include" . | indent 0 }}
{{- end }}
{{- end }}

{{- define "features.integrations.destinations" }}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.integrations.destinations) -}}
{{- end }}

{{- define "features.integrations.logs.discoveryRules" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraDiscoveryRules := list }}
{{- $logIntegrations := include "feature.integrations.configured.logs" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraDiscoveryRules = append $extraDiscoveryRules ((include (printf "integrations.%s.logs.discoveryRules" $integration) $values) | indent 0) }}
{{- end }}
{{ $extraDiscoveryRules | join "\n" }}
{{- end }}

{{- define "features.integrations.logs.logProcessingStages" }}
{{- $values := (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) }}
{{- $extraLogProcessingStages := "" }}
{{- $logIntegrations := include "feature.integrations.configured.logs" $values | fromYamlArray }}
{{- range $integration := $logIntegrations }}
  {{- $extraLogProcessingStages = cat $extraLogProcessingStages "\n" (include (printf "integrations.%s.logs.processingStage" $integration) $values) | indent 0 }}
{{- end }}
{{ $extraLogProcessingStages }}
{{- end }}

{{- define "features.integrations.validate" }}
{{- if eq (include "features.integrations.enabled" .) "true" }}
{{- $featureName := "Service Integrations" }}

{{- $metricIntegrations := include "feature.integrations.configured.metrics" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if $metricIntegrations }}
  {{- $metricDestinations := include "features.integrations.destinations" . | fromYamlArray }}
  {{- include "destinations.validate_destination_list" (dict "destinations" $metricDestinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
{{- end }}

{{- $podLogsEnabled := include "features.podLogs.enabled" $ }}
{{- $logIntegrations := include "feature.integrations.configured.logs" (dict "Values" .Values.integrations "Files" $.Subcharts.integrations.Files) | fromYamlArray }}
{{- if and $logIntegrations (ne $podLogsEnabled "true") }}
  {{- $msg := list "" "Service integrations that include logs requires enabling the Pod Logs feature." }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "podLogs:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}

{{- include "feature.integrations.validate" (dict "Values" $.Values.integrations) }}
{{- end }}
{{- end }}
