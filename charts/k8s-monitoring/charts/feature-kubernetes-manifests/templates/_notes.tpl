{{- define "feature.kubernetesManifests.notes.deployments" }}{{- end }}

{{- define "feature.kubernetesManifests.notes.task" }}
Gather Kubernetes manifests
{{- end }}

{{- define "feature.kubernetesManifests.notes.actions" }}{{- end }}

{{- define "feature.kubernetesManifests.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
