{{- define "feature.autoInstrumentation.validate" }}
{{- include "helper.validateRelabelCacheSettings" (dict "values" .Values "path" "autoInstrumentation") }}
{{- end }}
