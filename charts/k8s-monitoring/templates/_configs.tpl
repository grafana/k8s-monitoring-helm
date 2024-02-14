{{/* Grafana Agent config */}}
{{- define "agentConfig" -}}
  {{- include "agent.config.nodes" . }}
  {{- include "agent.config.services" . }}
  {{- include "agent.config.endpoints" . }}
  {{- include "agent.config.pods" . }}

  {{- include "agent.config.receivers.otlp" . }}
  {{- include "agent.config.receivers.jaeger" . }}
  {{- include "agent.config.receivers.zipkin" . }}
  {{- include "agent.config.receivers.remote_write" . }}

  {{- include "agent.config.processors" . }}

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

  {{- if and .Values.logs.enabled (or .Values.receivers.grpc.enabled .Values.receivers.http.enabled .Values.receivers.zipkin.enabled) }}
    {{- include "agent.config.logs.pod_logs_processor" . }}
    {{- include "agent.config.loki" . }}
  {{- end }}

  {{- if and .Values.traces.enabled }}
    {{- include "agent.config.tracesService" . }}
  {{- end }}

  {{- if .Values.extraConfig }}
    {{- print "\n" .Values.extraConfig }}
  {{- end }}
{{- end -}}

{{/* Grafana Agent Events config */}}
{{- define "agentEventsConfig" -}}
  {{- include "agent.config.logs.cluster_events" . }}
  {{- include "agent.config.loki" . }}
{{- end -}}

{{/* Grafana Agent Logs config */}}
{{- define "agentLogsConfig" -}}
  {{- include "agent.config.logs.pod_logs_discovery" . }}
  {{- include "agent.config.logs.pod_logs_processor" . }}
  {{- include "agent.config.loki" . }}

  {{- if .Values.logs.extraConfig }}
    {{- print "\n" .Values.logs.extraConfig }}
  {{- end }}
{{- end -}}
