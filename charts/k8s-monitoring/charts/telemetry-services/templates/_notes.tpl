{{- define "telemetry-services.notes.deployments" }}
{{- if dig "node-exporter" "deploy" false . }}
* Node Exporter (daemonset)
{{- end }}
{{- if dig "windows-exporter" "deploy" false . }}
* Windows Exporter (daemonset)
{{- end }}
{{- if dig "kube-state-metrics" "deploy" false . }}
* kube-state-metrics (deployment)
{{- end }}
{{- if dig "kepler" "deploy" false . }}
* Kepler (daemonset)
{{- end }}
{{- if dig "opencost" "deploy" false . }}
* OpenCost (deployment)
{{- end }}
{{- end }}
