{{- define "collectors.extraConfig.alloy" -}}
{{- $collectorValues := include "collector.alloy.allValues" . | fromYaml }}
  {{- if $collectorValues.extraConfig }}
{{ tpl $collectorValues.extraConfig $ | trim }}
  {{- end }}
{{- end -}}
