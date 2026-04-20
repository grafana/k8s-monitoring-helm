{{- define "collectors.notes.deployments" }}
{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- $type := $collectorValues.controller.type | default "daemonset" }}
  {{- $replicas := $collectorValues.controller.replicas | default 1 | int }}
  {{- if ne $type "daemonset" }}
    {{- $type = printf "%s, %d replica" $type $replicas }}
    {{- if gt $replicas 1 }}{{- $type = printf "%ss" $type }}{{- end }}
  {{- end }}
* Grafana Alloy "{{ $collectorName }}" ({{ $type }})
{{- end }}
{{- end }}
