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

{{- define "feature.clusterMetrics.summary" -}}
{{- $sources := list }}
{{- if .Values.controlPlane.enabled }}{{- $sources = append $sources "controlPlane" }}{{ end }}
{{- if .Values.kubelet.enabled }}{{- $sources = append $sources "kubelet" }}{{ end }}
{{- if .Values.kubeletResource.enabled }}{{- $sources = append $sources "kubeletResource" }}{{ end }}
{{- if .Values.cadvisor.enabled }}{{- $sources = append $sources "cadvisor" }}{{ end }}
{{- if .Values.apiServer.enabled }}{{- $sources = append $sources "apiServer" }}{{ end }}
{{- if .Values.kubeControllerManager.enabled }}{{- $sources = append $sources "kubeControllerManager" }}{{ end }}
{{- if .Values.kubeProxy.enabled }}{{- $sources = append $sources "kubeProxy" }}{{ end }}
{{- if .Values.kubeScheduler.enabled }}{{- $sources = append $sources "kubeScheduler" }}{{ end }}
{{- if (index .Values "kube-state-metrics").enabled }}{{- $sources = append $sources "kube-state-metrics" }}{{ end }}
{{- if (index .Values "node-exporter").enabled }}{{- $sources = append $sources "node-exporter" }}{{ end }}
{{- if (index .Values "windows-exporter").enabled }}{{- $sources = append $sources "windows-exporter" }}{{ end }}
{{- if .Values.kepler.enabled }}{{- $sources = append $sources "kepler" }}{{ end }}

{{- $deployments := list }}
{{- if (index .Values "kube-state-metrics").deploy }}{{- $deployments = append $deployments "kube-state-metrics" }}{{ end }}
{{- if (index .Values "node-exporter").deploy }}{{- $deployments = append $deployments "node-exporter" }}{{ end }}
{{- if (index .Values "windows-exporter").deploy }}{{- $deployments = append $deployments "windows-exporter" }}{{ end }}
{{- if .Values.kepler.enabled }}{{- $deployments = append $deployments "kepler" }}{{ end }}
version: {{ .Chart.Version }}
sources: {{ $sources | join "," }}
deployments: {{ $deployments | join "," }}
{{- end }}
