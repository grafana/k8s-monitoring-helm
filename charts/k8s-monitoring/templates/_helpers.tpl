{{/* This template checks that the port defined in .Values.receivers.<protocol>.port is in the targetPort list on .alloy */}}
{{- define "checkforAlloyPort" -}}
  {{- $port := .port -}}
  {{- $found := false -}}
  {{- range .alloy.extraPorts -}}
    {{- if eq .targetPort $port }}
      {{- $found = true -}}
    {{- end }}
  {{- end }}
  {{- if not $found }}
    {{- fail (print .type " port not opened on Grafana Alloy.\nIn order to receive data over this protocol, port " .port " needs to be opened on Alloy. For example, set this in your values file:\nalloy:\n  alloy:\n    extraPorts:\n      - name: \"" (lower .type | replace " " "-") "\"\n        port: " .port "\n        targetPort: " .port "\n        protocol: \"TCP\"\nFor more examples, see https://github.com/grafana/k8s-monitoring-helm/tree/main/examples/traces-enabled") -}}
  {{- end -}}
{{- end -}}

{{- define "kubernetes_monitoring_telemetry.metrics" -}}
{{- $metrics := list -}}
{{- if .Values.metrics.enabled -}}
  {{- $metrics = append $metrics "enabled" -}}
  {{- if .Values.metrics.alloy.enabled -}}{{- $metrics = append $metrics "alloy" -}}{{- end -}}
  {{- if .Values.metrics.autoDiscover.enabled -}}{{- $metrics = append $metrics "autoDiscover" -}}{{- end -}}
  {{- if index (index .Values.metrics "kube-state-metrics").enabled -}}{{- $metrics = append $metrics "kube-state-metrics" -}}{{- end -}}
  {{- if index (index .Values.metrics "node-exporter").enabled -}}{{- $metrics = append $metrics "node-exporter" -}}{{- end -}}
  {{- if index (index .Values.metrics "windows-exporter").enabled -}}{{- $metrics = append $metrics "windows-exporter" -}}{{- end -}}
  {{- if .Values.metrics.kubelet.enabled -}}{{- $metrics = append $metrics "kubelet" -}}{{- end -}}
  {{- if .Values.metrics.cadvisor.enabled -}}{{- $metrics = append $metrics "cadvisor" -}}{{- end -}}
  {{- if .Values.metrics.apiserver.enabled -}}{{- $metrics = append $metrics "apiserver" }}{{ end -}}
  {{- if .Values.metrics.cost.enabled -}}{{- $metrics = append $metrics "cost" }}{{ end -}}
  {{- if .Values.metrics.kepler.enabled -}}{{- $metrics = append $metrics "kepler" }}{{ end -}}
  {{- if or .Values.alloy.extraConfig .Values.extraConfig -}}{{- $metrics = append $metrics "extraConfig" }}{{ end -}}
{{- else -}}
  {{- $metrics = append $metrics "disabled" -}}
{{- end -}}
{{- join "," $metrics -}}
{{- end }}

{{- define "kubernetes_monitoring_telemetry.logs" -}}
{{- $logs := list -}}
{{- if .Values.logs.enabled -}}
  {{- $logs = append $logs "enabled" -}}
  {{- if .Values.logs.cluster_events.enabled }}{{- $logs = append $logs "events" -}}{{- end -}}
  {{- if .Values.logs.pod_logs.enabled }}{{- $logs = append $logs "pod_logs" -}}{{- end -}}
  {{- if .Values.logs.journal.enabled }}{{- $logs = append $logs "journal" -}}{{- end -}}
  {{- if or .Values.logs.extraConfig (index .Values "alloy-logs").extraConfig }}{{- $logs = append $logs "extraConfig" }}{{ end -}}
  {{- if or .Values.logs.cluster_events.extraConfig (index .Values "alloy-events").extraConfig }}{{- $logs = append $logs "eventsExtraConfig" }}{{ end -}}
{{- else -}}
  {{- $logs = append $logs "disabled" -}}
{{- end -}}
{{- join "," $logs -}}
{{- end }}

{{- define "kubernetes_monitoring_telemetry.traces" -}}
{{- if .Values.traces.enabled }}enabled{{- else -}}disabled{{- end -}}
{{- end }}

{{- define "kubernetes_monitoring_telemetry.profiles" -}}
{{- $profiles := list -}}
{{- if .Values.profiles.enabled -}}
  {{- $profiles = append $profiles "enabled" -}}
  {{- if (index .Values "alloy-profiles").extraConfig }}{{- $profiles = append $profiles "extraConfig" }}{{ end -}}
{{- else -}}
  {{- $profiles = append $profiles "disabled" -}}
{{- end -}}
{{- join "," $profiles -}}
{{- end }}

{{- define "kubernetes_monitoring_telemetry.deployments" -}}
{{- $deployments := list -}}
{{- if index (index .Values "kube-state-metrics").enabled -}}{{- $deployments = append $deployments "kube-state-metrics" -}}{{- end -}}
{{- if index (index .Values "prometheus-node-exporter").enabled -}}{{- $deployments = append $deployments "prometheus-node-exporter" -}}{{- end -}}
{{- if index (index .Values "prometheus-windows-exporter").enabled -}}{{- $deployments = append $deployments "prometheus-windows-exporter" -}}{{- end -}}
{{- if index (index .Values "prometheus-operator-crds").enabled -}}{{- $deployments = append $deployments "prometheus-operator-crds" -}}{{- end -}}
{{- if index .Values.opencost.enabled -}}{{- $deployments = append $deployments "opencost" -}}{{- end -}}
{{- if index .Values.kepler.enabled -}}{{- $deployments = append $deployments "kepler" -}}{{- end -}}
{{- join "," $deployments -}}
{{- end }}

{{- define "kubernetes_monitoring.metrics_service.secret.name" -}}
{{- if .Values.externalServices.prometheus.secret.name }}
  {{- .Values.externalServices.prometheus.secret.name }}
{{- else }}
  {{- printf "prometheus-%s" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "kubernetes_monitoring.logs_service.secret.name" -}}
{{- if .Values.externalServices.loki.secret.name }}
  {{- .Values.externalServices.loki.secret.name }}
{{- else }}
  {{- printf "loki-%s" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "kubernetes_monitoring.traces_service.secret.name" -}}
{{- if .Values.externalServices.tempo.secret.name }}
  {{- .Values.externalServices.tempo.secret.name }}
{{- else }}
  {{- printf "tempo-%s" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "kubernetes_monitoring.profiles_service.secret.name" -}}
{{- if .Values.externalServices.pyroscope.secret.name }}
  {{- .Values.externalServices.pyroscope.secret.name }}
{{- else }}
  {{- printf "pyroscope-%s" .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "escape_label" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}

{{- define "grafana-agent.fullname" -}}
{{- if (index .Values "grafana-agent").fullnameOverride }}
{{- (index .Values "grafana-agent").fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "grafana-agent" (index .Values "grafana-agent").nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}
