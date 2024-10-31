{{- define "collectors.validate.featuresEnabled" }}
{{- $msg := list "" "The %s collector is enabled, but there are no enabled features that will use it. Please disable the collector by setting:" }}
{{- $msg = append $msg "%s:" }}
{{- $msg = append $msg "  enabled: false" }}
{{- $errorMessage := join "\n" $msg }}

{{- $collectorName := "alloy-metrics" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := or .Values.clusterMetrics.enabled .Values.annotationAutodiscovery.enabled .Values.prometheusOperatorObjects.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).remoteConfig.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).extraConfig }}
  {{- $integrationsConfigured := include "feature.integrations.configured.metrics" .Subcharts.integrations | fromYamlArray }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (not (empty $integrationsConfigured)) }}

  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- $collectorName = "alloy-singleton" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := .Values.clusterEvents.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).remoteConfig.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).extraConfig }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- $collectorName = "alloy-logs" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := .Values.podLogs.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).remoteConfig.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).extraConfig }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- $collectorName = "alloy-receiver" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := or .Values.applicationObservability.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).remoteConfig.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).extraConfig }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}

{{- $collectorName = "alloy-profiles" }}
{{- if (index .Values $collectorName).enabled }}
  {{- $atLeastOneFeatureEnabled := .Values.profiling.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).remoteConfig.enabled }}
  {{- $atLeastOneFeatureEnabled = or $atLeastOneFeatureEnabled (index .Values $collectorName).extraConfig }}
  {{- if not $atLeastOneFeatureEnabled }}
    {{- fail (printf $errorMessage $collectorName $collectorName) }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "collectors.validate.liveDebugging" }}
{{- if (index .Values .collectorName).enabled }}
  {{- if (index .Values .collectorName).liveDebugging.enabled }}
    {{- if not (eq (index .Values .collectorName).alloy.stabilityLevel "experimental") }}
      {{- $msg := list "" "The live debugging feature requires Alloy to use the \"experimental\" stability level. Please set:" }}
      {{- $msg = append $msg (printf "%s:" .collectorName ) }}
      {{- $msg = append $msg "  alloy:" }}
      {{- $msg = append $msg "    stabilityLevel: experimental" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}

{{- define "collectors.validate.remoteConfig" }}
{{- if (index .Values .collectorName).enabled }}
  {{- if (index .Values .collectorName).remoteConfig.enabled }}
    {{- if not (has (index .Values .collectorName).alloy.stabilityLevel (list "public-preview" "experimental")) }}
      {{- $msg := list "" "The remote configuratino feature requires Alloy to use the \"public-preview\" stability level. Please set:" }}
      {{- $msg = append $msg (printf "%s:" .collectorName ) }}
      {{- $msg = append $msg "  alloy:" }}
      {{- $msg = append $msg "    stabilityLevel: public-preview" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}

