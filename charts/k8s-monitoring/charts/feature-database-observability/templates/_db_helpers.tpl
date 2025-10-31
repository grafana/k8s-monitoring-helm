{{/* Inputs: . (Values) */}}
{{- define "feature.databaseObservability.configured.metrics" }}
  {{- range $type := (include "databases.types" .) | fromYamlArray }}
    {{- if (index $.Values $type).instances }}
      {{- if eq (include (printf "databaseObservability.%s.type.metrics" $type) $) "true" }}
- {{ $type }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Inputs: . (Values) */}}
{{- define "feature.databaseObservability.configured.logs" }}
  {{- range $type := (include "databases.types" .) | fromYamlArray }}
    {{- if (index $.Values $type).instances }}
      {{- if eq (include (printf "databaseObservability.%s.type.logs" $type) $) "true" }}
- {{ $type }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
