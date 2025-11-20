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
{{- define "feature.integrations.configured.logRules" }}
  {{- range $type := (include "integrations.types" .) | fromYamlArray }}
    {{- if (index $.Values $type).instances }}
      {{- if eq (include (printf "integrations.%s.type.logRules" $type) $) "true" }}
- {{ $type }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Inputs: . (Values) */}}
{{- define "feature.integrations.configured.logOutput" }}
  {{- range $type := (include "integrations.types" .) | fromYamlArray }}
    {{- if (index $.Values $type).instances }}
      {{- if eq (include (printf "integrations.%s.type.logOutput" $type) $) "true" }}
- {{ $type }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
