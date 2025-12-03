{{- define "feature.kubernetesManifests.module" }}
declare "kubernetes_manifests" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }
{{- if .Values.kinds.pods.gather }}
{{ include "feature.kubernetesManifests.pods" . | nindent 2 }}
{{- end }}
{{- if .Values.kinds.deployments.gather }}
{{ include "feature.kubernetesManifests.workload" (dict "kind" "deployment" "Values" .Values "Release" .Release) | nindent 2 }}
{{- end }}
{{- if .Values.kinds.statefulsets.gather }}
{{ include "feature.kubernetesManifests.workload" (dict "kind" "statefulset" "Values" .Values "Release" .Release) | nindent 2 }}
{{- end }}
{{- if .Values.kinds.daemonsets.gather }}
{{ include "feature.kubernetesManifests.workload" (dict "kind" "daemonset" "Values" .Values "Release" .Release) | nindent 2 }}
{{- end }}
{{- if .Values.kinds.cronjobs.gather }}
{{ include "feature.kubernetesManifests.workload" (dict "kind" "cronjob" "Values" .Values "Release" .Release) | nindent 2 }}
{{- end }}
}
{{- end -}}
