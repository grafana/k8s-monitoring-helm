{{- define "collectors.validate.featuresEnabled" }}
{{- $msg := list "" "The %s collector is enabled, but there are no enabled features that will use it. Please disable the collector by setting:" }}
{{- $msg = append $msg "%s:" }}
{{- $msg = append $msg "  enabled: false" }}
{{- $errorMessage := join "\n" $msg }}

{{- $collectorsUtilized := list }}
{{- range $feature := include "features.list.enabled" . | fromYamlArray }}
  {{- $collectorsUtilized = concat $collectorsUtilized (include (printf "features.%s.collectors" $feature) $ | fromYamlArray) }}
{{- end }}

{{- range $collector := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $usedByAFeature := has $collector $collectorsUtilized }}
  {{- $extraConfigDefined := not (not (index $.Values $collector).extraConfig) }}
  {{- $remoteConfigEnabled := (index $.Values $collector).remoteConfig.enabled }}
  {{- if not (or $usedByAFeature $extraConfigDefined $remoteConfigEnabled) }}
    {{- fail (printf $errorMessage $collector $collector) }}
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
