{{/*
Create a default fully qualified name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "config-validator.fullname" -}}
  {{- if contains .Chart.Name .Release.Name }}
    {{- printf "validate-%s" .Release.Name | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- printf "validate-%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
  {{- end }}
{{- end }}
