{{- define "feature.integrations.validate" }}
  {{- range $type := (include "integrations.types" .) | fromYamlArray }}
    {{ include (printf "integrations.%s.validate" $type) $ }}
  {{- end }}
{{- end }}
