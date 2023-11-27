{{/* This template checks that the port defined in .Values.traces.receiver.port is in the targetPort list on .grafana-agent */}}
{{- define "checkforTracePort" -}}
  {{- $port := .port -}}
  {{- $found := false -}}
  {{- range .agent.extraPorts -}}
    {{- if eq .targetPort $port }}
      {{- $found = true -}}
    {{- end }}
  {{- end }}
  {{- if not $found }}
    {{- fail (print .type " trace port not opened on the Grafana Agent.\nIn order for traces to work, the " .port " port needs to be opened on the Grafana Agent. For example, set this in your values file:\ngrafana-agent:\n  agent:\n    extraPorts:\n      - name: \"" (lower .type | replace " " "-") "\"\n        port: " .port "\n        targetPort: " .port "\n        protocol: \"TCP\"\nFor more examples, see https://github.com/grafana/k8s-monitoring-helm/tree/main/examples/traces-enabled") -}}
  {{- end -}}
{{- end -}}

{{/* Grafana Agent config */}}
{{- define "agentConfig" -}}
  {{- include "agent.config.nodes" . }}
  {{- include "agent.config.pods" . }}
  {{- include "agent.config.services" . }}

  {{- if .Values.metrics.enabled }}
    {{- if .Values.metrics.autoDiscover.enabled }}
      {{- include "agent.config.annotationAutodiscovery" . }}
    {{- end }}

    {{- if .Values.metrics.agent.enabled }}
      {{- include "agent.config.agent" . }}
    {{- end }}

    {{- if .Values.metrics.kubernetesMonitoring.enabled }}
      {{- include "agent.config.kubernetes_monitoring_telemetry" . }}
    {{- end }}

    {{- if .Values.metrics.kubelet.enabled }}
      {{- include "agent.config.kubelet" . }}
    {{- end }}

    {{- if .Values.metrics.cadvisor.enabled }}
      {{- include "agent.config.cadvisor" . }}
    {{- end }}

    {{- if .Values.metrics.apiserver.enabled }}
      {{- include "agent.config.apiserver" . }}
    {{- end }}

    {{- if .Values.metrics.kubeControllerManager.enabled }}
      {{- include "agent.config.kube_controller_manager" . }}
    {{- end }}

    {{- if .Values.metrics.kubeScheduler.enabled }}
      {{- include "agent.config.kube_scheduler" . }}
    {{- end }}

    {{- if .Values.metrics.kubeProxy.enabled }}
      {{- include "agent.config.kube_proxy" . }}
    {{- end }}

    {{- if (index .Values.metrics "kube-state-metrics").enabled }}
      {{- include "agent.config.kube_state_metrics" . }}
    {{- end }}

    {{- if (index .Values.metrics "node-exporter").enabled }}
      {{- include "agent.config.node_exporter" . }}
    {{- end }}

    {{- if (index .Values.metrics "windows-exporter").enabled }}
      {{- include "agent.config.windows_exporter" . }}
    {{- end }}

    {{- if .Values.metrics.cost.enabled }}
      {{- include "agent.config.opencost" . }}
    {{- end }}

    {{- if .Values.metrics.podMonitors.enabled }}
      {{- include "agent.config.pod_monitors" . }}
    {{- end }}

    {{- if .Values.metrics.probes.enabled }}
      {{- include "agent.config.probes" . }}
    {{- end }}

    {{- if .Values.metrics.serviceMonitors.enabled }}
      {{- include "agent.config.service_monitors" . }}
    {{- end }}

    {{- include "agent.config.metricsService" . }}
  {{- end }}

  {{- if and .Values.logs.enabled .Values.logs.cluster_events.enabled }}
    {{- include "agent.config.logs.cluster_events" . }}
    {{- include "agent.config.loki" . }}
  {{- end }}

  {{- if and .Values.traces.enabled }}
    {{- include "agent.config.traces" . }}
    {{- include "agent.config.tracesService" . }}
  {{- end }}

  {{- if .Values.extraConfig }}
    {{- print "\n" .Values.extraConfig }}
  {{- end }}
{{- end -}}

{{/* Grafana Agent Logs config */}}
{{- define "agentLogsConfig" -}}
  {{- include "agent.config.logs.pod_logs" . }}
  {{- include "agent.config.loki" . }}

  {{- if .Values.logs.extraConfig }}
    {{- print "\n" .Values.logs.extraConfig }}
  {{- end }}
{{- end -}}

{{- define "kubernetes_monitoring_telemetry.metrics" -}}
{{- $metrics := list -}}
{{- if .Values.metrics.enabled -}}
  {{- $metrics = append $metrics "enabled" -}}
  {{- if .Values.metrics.agent.enabled -}}{{- $metrics = append $metrics "agent" -}}{{- end -}}
  {{- if .Values.metrics.autoDiscover.enabled -}}{{- $metrics = append $metrics "autoDiscover" -}}{{- end -}}
  {{- if index (index .Values.metrics "kube-state-metrics").enabled -}}{{- $metrics = append $metrics "kube-state-metrics" -}}{{- end -}}
  {{- if index (index .Values.metrics "node-exporter").enabled -}}{{- $metrics = append $metrics "node-exporter" -}}{{- end -}}
  {{- if index (index .Values.metrics "windows-exporter").enabled -}}{{- $metrics = append $metrics "windows-exporter" -}}{{- end -}}
  {{- if .Values.metrics.kubelet.enabled -}}{{- $metrics = append $metrics "kubelet" -}}{{- end -}}
  {{- if .Values.metrics.cadvisor.enabled -}}{{- $metrics = append $metrics "cadvisor" -}}{{- end -}}
  {{- if .Values.metrics.apiserver.enabled -}}{{- $metrics = append $metrics "apiserver" }}{{ end -}}
  {{- if .Values.metrics.cost.enabled -}}{{- $metrics = append $metrics "cost" }}{{ end -}}
  {{- if .Values.extraConfig -}}{{- $metrics = append $metrics "extraConfig" }}{{ end -}}
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
  {{- if .Values.logs.extraConfig -}}{{- $logs = append $logs "extraConfig" }}{{ end -}}
{{- else -}}
  {{- $logs = append $logs "disabled" -}}
{{- end -}}
{{- join "," $logs -}}
{{- end }}

{{- define "kubernetes_monitoring_telemetry.traces" -}}
{{- if .Values.traces.enabled }}enabled{{- else -}}disabled{{- end -}}
{{- end }}

{{- define "kubernetes_monitoring_telemetry.deployments" -}}
{{- $deployments := list -}}
{{- if index (index .Values "kube-state-metrics").enabled -}}{{- $deployments = append $deployments "kube-state-metrics" -}}{{- end -}}
{{- if index (index .Values "prometheus-node-exporter").enabled -}}{{- $deployments = append $deployments "prometheus-node-exporter" -}}{{- end -}}
{{- if index (index .Values "prometheus-windows-exporter").enabled -}}{{- $deployments = append $deployments "prometheus-windows-exporter" -}}{{- end -}}
{{- if index (index .Values "prometheus-operator-crds").enabled -}}{{- $deployments = append $deployments "prometheus-operator-crds" -}}{{- end -}}
{{- if index (index .Values "opencost").enabled -}}{{- $deployments = append $deployments "opencost" -}}{{- end -}}
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

{{- define "escape_label" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}
