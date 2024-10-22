{{- define "collectors.notes.deployments" }}
{{- range $collector := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $type := (index $.Values $collector).controller.type }}
  {{- $replicas := (index $.Values $collector).controller.replicas | default 1 | int }}
  {{- if ne $type "daemonset" }}
    {{- $type = printf "%s, %d replica" $type $replicas }}
    {{- if gt $replicas 1 }}{{- $type = printf "%ss" $type }}{{- end }}
  {{- end }}
* Grafana Alloy "{{ $collector }}" ({{ $type }})
{{- end }}
{{- end }}
