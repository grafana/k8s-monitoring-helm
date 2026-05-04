{{- define "feature.kubernetesManifests.notes.deployments" }}{{- end }}

{{- define "feature.kubernetesManifests.notes.task" }}
Gather Kubernetes resource manifest changes as logs
{{- end }}

{{- define "feature.kubernetesManifests.notes.actions" }}{{- end }}

{{- define "feature.kubernetesManifests.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
