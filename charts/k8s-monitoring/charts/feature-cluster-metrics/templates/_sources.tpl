{{- define "feature.clusterMetrics.controlPlaneSource.enabled" -}}
{{- $source := index .Values .source -}}
{{- if or $source.enabled (and .Values.controlPlane.enabled (not (eq $source.enabled false))) }}true{{ else }}false{{ end -}}
{{- end }}

{{- define "feature.clusterMetrics.apiServer.enabled" -}}
{{- include "feature.clusterMetrics.controlPlaneSource.enabled" (dict "Values" .Values "source" "apiServer") -}}
{{- end }}

{{- define "feature.clusterMetrics.kubeControllerManager.enabled" -}}
{{- include "feature.clusterMetrics.controlPlaneSource.enabled" (dict "Values" .Values "source" "kubeControllerManager") -}}
{{- end }}

{{- define "feature.clusterMetrics.kubeDNS.enabled" -}}
{{- include "feature.clusterMetrics.controlPlaneSource.enabled" (dict "Values" .Values "source" "kubeDNS") -}}
{{- end }}

{{- define "feature.clusterMetrics.kubeProxy.enabled" -}}
{{- include "feature.clusterMetrics.controlPlaneSource.enabled" (dict "Values" .Values "source" "kubeProxy") -}}
{{- end }}

{{- define "feature.clusterMetrics.kubeScheduler.enabled" -}}
{{- include "feature.clusterMetrics.controlPlaneSource.enabled" (dict "Values" .Values "source" "kubeScheduler") -}}
{{- end }}

{{/* The namespace kube-state-metrics is discovered in, or empty for every namespace. */}}
{{- define "feature.clusterMetrics.kube_state_metrics.namespace" -}}
{{- $namespace := (index .Values "kube-state-metrics").namespace -}}
{{- if dig "kube-state-metrics" "deploy" false (.telemetryServices | default dict) -}}
  {{- $namespace = (dig "kube-state-metrics" "namespaceOverride" false (.telemetryServices | default dict) | default .Release.Namespace) -}}
{{- end -}}
{{- $namespace -}}
{{- end }}
