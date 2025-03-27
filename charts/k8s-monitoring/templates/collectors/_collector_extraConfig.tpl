{{- define "collectors.extraConfig.alloy" -}}
{{- $collectorValues := include "collector.alloy.values" . | fromYaml }}
  {{- if $collectorValues.extraConfig }}
{{ tpl $collectorValues.extraConfig $ | trim }}
  {{- end }}
{{- end -}}
