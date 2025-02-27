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
