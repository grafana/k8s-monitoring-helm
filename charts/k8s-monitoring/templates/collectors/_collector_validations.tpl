{{- define "collectors.validate.featuresEnabled" }}
{{- $errorMessage := "\nThe %s collector is enabled, but there are no enabled features that will use it. Please disable the collector by setting:\n%s:\n  enabled: false" }}

{{- if (index .Values "alloy-metrics").enabled }}
  {{- $collectorName := "alloy-metrics" }}

  {{- $atLeastOneFeatureEnabled := or .Values.clusterMetrics.enabled .Values.annotationAutodiscovery.enabled .Values.prometheusOperatorObjects.enabled }}
  {{- $integrationsConfigured := include "feature.integrations.configured.metrics" .Subcharts.integrations | fromYamlArray }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (not (empty $integrationsConfigured)) }}

  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- if (index .Values "alloy-singleton").enabled }}
  {{- $collectorName := "alloy-singleton" }}
  {{- $atLeastOneFeatureEnabled := .Values.clusterEvents.enabled }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- if (index .Values "alloy-logs").enabled }}
  {{- $collectorName := "alloy-logs" }}
  {{- $atLeastOneFeatureEnabled := .Values.podLogs.enabled }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- if (index .Values "alloy-receiver").enabled }}
  {{- $collectorName := "alloy-receiver" }}
  {{- $atLeastOneFeatureEnabled := or .Values.applicationObservability.enabled .Values.frontendObservability.enabled }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- if (index .Values "alloy-profiles").enabled }}
  {{- $collectorName := "alloy-profiles" }}
  {{- $atLeastOneFeatureEnabled := .Values.profiling.enabled }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}
{{- end }}
