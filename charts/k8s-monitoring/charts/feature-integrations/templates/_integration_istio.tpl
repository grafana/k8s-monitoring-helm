{{- define "integrations.istio.validate" }}
  {{- range $instance := $.Values.istio.instances }}
    {{- $defaultValues := fromYaml ($.Files.Get "integrations/istio-values.yaml") }}
    {{- include "integrations.istio.instance.validate" (dict "instance" (mergeOverwrite $defaultValues $instance (dict "type" "integration.istio"))) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.istio.instance.validate" }}{{- end }}
