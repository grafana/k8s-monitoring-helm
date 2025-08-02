{{- define "cluster.getClusterName" }}
{{- if .Values.cluster.name }}
  {{- .Values.cluster.name | quote }}
{{- else if .Values.cluster.nameFrom }}
  {{- .Values.cluster.nameFrom }}
{{- end }}
{{- end }}
