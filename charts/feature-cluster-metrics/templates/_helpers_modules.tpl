{{/* Loads a module from Alloy Modules*/}}
{{/* Inputs: . ($), name (string), path (string)*/}}
{{- define "alloyModules.load" }}
{{- if eq .Values.global.alloyModules.source "configMap" }}
{{- $pathParts := regexSplit "/" .path -1 }}
{{- $configMapName := printf "%s-alloy-module-%s" (include "helper.global_fullname" .) (index $pathParts 1) }}
{{- $moduleFile := (slice $pathParts 2) | join "_" }}
remote.kubernetes.configmap {{ .name | quote }} {
  name = {{ $configMapName | quote }}
  namespace = {{ .Release.Namespace | quote }}
}

import.string {{ .name | quote }} {
  content = remote.kubernetes.configmap.{{ .name }}.data[{{ $moduleFile | quote }}]
}
{{- else if eq .Values.global.alloyModules.source "git" }}
import.git {{ .name | quote }} {
  repository = "https://github.com/grafana/alloy-modules.git"
  revision = "main"
  path = {{ .path | quote }}
  pull_frequency = "15m"
}
{{- end }}
{{- end }}
