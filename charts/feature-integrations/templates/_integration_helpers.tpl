{{/* Inputs: . (Values) */}}
{{- define "feature.integrations.configured.metrics" }}
  {{- range $type := (include "integrations.types" .) | fromYamlArray }}
    {{- if (index $.Values $type).instances }}
      {{- if eq (include (printf "integrations.%s.type.metrics" $type) $) "true" }}
- {{ $type }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Inputs: . (Values) */}}
{{- define "feature.integrations.configured.logs" }}
  {{- range $type := (include "integrations.types" .) | fromYamlArray }}
    {{- if (index $.Values $type).instances }}
      {{- if eq (include (printf "integrations.%s.type.logs" $type) $) "true" }}
- {{ $type }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
