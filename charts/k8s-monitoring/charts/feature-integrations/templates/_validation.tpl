{{- define "feature.integrations.validate" }}
  {{- range $type := (include "integrations.types" .) | fromYamlArray }}
    {{ include (printf "integrations.%s.validate" $type) $ }}
    {{- range $i, $instance := (index $.Values $type).instances }}
      {{- include "helper.validateRelabelCacheSettings" (dict "values" $instance "path" (printf "integrations.%s.instances[%d]" $type $i)) }}
    {{- end }}
  {{- end }}
{{- end }}
