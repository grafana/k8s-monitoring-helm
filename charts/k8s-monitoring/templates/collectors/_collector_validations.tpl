{{- define "collectors.validate.featuresEnabled" }}
{{- $msg := list "" "The %s collector is enabled, but there are no enabled features that will use it. Please disable the collector by setting:" }}
{{- $msg = append $msg "%s:" }}
{{- $msg = append $msg "  enabled: false" }}
{{- $errorMessage := join "\n" $msg }}

{{- $collectorName := "alloy-metrics" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := or .Values.clusterMetrics.enabled .Values.annotationAutodiscovery.enabled .Values.prometheusOperatorObjects.enabled }}
  {{- $integrationsConfigured := include "feature.integrations.configured.metrics" .Subcharts.integrations | fromYamlArray }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (not (empty $integrationsConfigured)) }}

  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- $collectorName = "alloy-singleton" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := .Values.clusterEvents.enabled }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- $collectorName = "alloy-logs" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := .Values.podLogs.enabled }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- $collectorName = "alloy-receiver" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := or .Values.applicationObservability.enabled }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- $collectorName = "alloy-profiles" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := .Values.profiling.enabled }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "collectors.validate.liveDebugging" }}
{{- if (index .Values .collectorName).enabled }}
  {{- if (index .Values .collectorName).liveDebugging.enabled }}
    {{- if not (eq (index .Values .collectorName).alloy.stabilityLevel "experimental") }}
      {{- $msg := list "" "The live debugging feature requires Alloy to use the \"experiemenal\" stability level. Please set:" }}
      {{- $msg = append $msg (printf "%s:" .collectorName ) }}
      {{- $msg = append $msg "  alloy:" }}
      {{- $msg = append $msg "    stabilityLevel: experimental" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
