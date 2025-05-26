{{- define "collectors.validate.featuresEnabled" }}
{{- $collectorsUtilized := list }}
{{- range $feature := include "features.list.enabled" . | fromYamlArray }}
  {{- $collectorsUtilized = concat $collectorsUtilized (include (printf "features.%s.collectors" $feature) $ | fromYamlArray) }}
{{- end }}

{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $usedByAFeature := has $collectorName $collectorsUtilized }}
  {{- $collectorValues := include "collector.alloy.values" (deepCopy $ | merge (dict "collectorName" $collectorName)) | fromYaml }}
  {{- $extraConfigDefined := not (not $collectorValues.extraConfig) }}
  {{- $remoteConfigEnabled := $collectorValues.remoteConfig.enabled }}
  {{- if not (or $usedByAFeature $extraConfigDefined $remoteConfigEnabled) }}
    {{- $msg := list "" (printf "The %s collector is enabled, but there are no enabled features that will use it." $collectorName) }}
    {{- $msg = append $msg "Please disable the collector by setting:" }}
    {{- $msg = append $msg (printf "%s:" $collectorName) }}
    {{- $msg = append $msg "  enabled: false" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}
