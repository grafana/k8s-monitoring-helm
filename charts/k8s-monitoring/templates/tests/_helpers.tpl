{{/*
Create a default fully qualified name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubernetes-monitoring-test.fullname" -}}
  {{- if contains .Chart.Name .Release.Name }}
    {{- printf "test-%s" .Release.Name | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- printf "test-%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
  {{- end }}
{{- end }}
