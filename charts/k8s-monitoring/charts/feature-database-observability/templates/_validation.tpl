{{- define "feature.databaseObservability.validate" }}
  {{- range $type := (include "databases.types" .) | fromYamlArray }}
    {{ include (printf "databaseObservability.%s.validate" $type) $ }}
  {{- end }}
{{- end }}
