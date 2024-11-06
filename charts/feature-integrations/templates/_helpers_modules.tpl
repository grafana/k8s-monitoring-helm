{{/* Loads a module from Alloy Modules*/}}
{{/* Inputs: . ($), name (string), path (string)*/}}
{{- define "alloyModules.load" }}
{{- if eq .Values.global.alloyModules.source "configMap" }}
{{- $pathParts := regexSplit "/" .path -1 }}
{{- $configMapName := printf "%s-alloy-module-%s" $.Release.Name (index $pathParts 1) }}
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

{{- define "feature.integrations.alloyModules" }}
{{- if .Values.etcd.instances }}
- modules/databases/kv/etcd/metrics.alloy
{{- end }}
{{- if (index .Values "cert-manager").instances }}
- modules/kubernetes/cert-manager/metrics.alloy
{{- end }}
{{- end }}
