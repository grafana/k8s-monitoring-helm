{{- define "feature.clusterMetrics.notes.deployments" }}
{{- if (index .Values "kube-state-metrics").deploy }}
* kube-state-metrics (Deployment)
{{- end }}
{{- if (index .Values "node-exporter").deploy }}
* Node Exporter (DaemonSet)
{{- end }}
{{- if (index .Values "windows-exporter").deploy }}
* Windows Exporter (DaemonSet)
{{- end }}
{{- if .Values.kepler.enabled }}
* Kepler (DaemonSet)
{{- end }}
{{- end }}

{{- define "feature.clusterMetrics.notes.task" }}
Scrape Kubernetes Cluster metrics
{{- end }}

{{- define "feature.clusterMetrics.notes.actions" }}{{- end }}
