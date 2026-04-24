{{- define "feature.kubernetesManifests.notes.deployments" }}{{- end }}

{{- define "feature.kubernetesManifests.notes.task" }}
Collect Kubernetes manifest changes as logs from k8s-manifest-tail
{{- end }}

{{- define "feature.kubernetesManifests.notes.actions" }}{{- end }}

{{- define "feature.kubernetesManifests.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
