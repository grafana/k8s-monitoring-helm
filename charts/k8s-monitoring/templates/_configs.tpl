{{/* Grafana Alloy config */}}
{{- define "alloyConfig" -}}
  {{- include "alloy.config.nodes" . }}
  {{- include "alloy.config.services" . }}
  {{- include "alloy.config.endpoints" . }}
  {{- include "alloy.config.pods" . }}

  {{- include "alloy.config.receivers.otlp" . }}
  {{- include "alloy.config.receivers.jaeger" . }}
  {{- include "alloy.config.receivers.zipkin" . }}
  {{- include "alloy.config.receivers.remote_write" . }}

  {{- include "alloy.config.processors" . }}

  {{- if .Values.metrics.enabled }}
    {{- if .Values.metrics.autoDiscover.enabled }}
      {{- include "alloy.config.annotationAutodiscovery" . }}
    {{- end }}

    {{- if .Values.metrics.alloy.enabled }}
      {{- include "alloy.config.alloy" . }}
    {{- end }}

    {{- if .Values.metrics.kubernetesMonitoring.enabled }}
      {{- include "alloy.config.kubernetes_monitoring_telemetry" . }}
    {{- end }}

    {{- if .Values.metrics.kubelet.enabled }}
      {{- include "alloy.config.kubelet" . }}
    {{- end }}

    {{- if .Values.metrics.cadvisor.enabled }}
      {{- include "alloy.config.cadvisor" . }}
    {{- end }}

    {{- if .Values.metrics.apiserver.enabled }}
      {{- include "alloy.config.apiserver" . }}
    {{- end }}

    {{- if .Values.metrics.kubeControllerManager.enabled }}
      {{- include "alloy.config.kube_controller_manager" . }}
    {{- end }}

    {{- if .Values.metrics.kubeScheduler.enabled }}
      {{- include "alloy.config.kube_scheduler" . }}
    {{- end }}

    {{- if .Values.metrics.kubeProxy.enabled }}
      {{- include "alloy.config.kube_proxy" . }}
    {{- end }}

    {{- if (index .Values.metrics "kube-state-metrics").enabled }}
      {{- include "alloy.config.kube_state_metrics" . }}
    {{- end }}

    {{- if (index .Values.metrics "node-exporter").enabled }}
      {{- include "alloy.config.node_exporter" . }}
    {{- end }}

    {{- if (index .Values.metrics "windows-exporter").enabled }}
      {{- include "alloy.config.windows_exporter" . }}
    {{- end }}

    {{- if .Values.metrics.cost.enabled }}
      {{- include "alloy.config.opencost" . }}
    {{- end }}

    {{- if .Values.metrics.podMonitors.enabled }}
      {{- include "alloy.config.pod_monitors" . }}
    {{- end }}

    {{- if .Values.metrics.probes.enabled }}
      {{- include "alloy.config.probes" . }}
    {{- end }}

    {{- if .Values.metrics.serviceMonitors.enabled }}
      {{- include "alloy.config.service_monitors" . }}
    {{- end }}

    {{- include "alloy.config.metricsService" . }}
  {{- end }}

  {{- if and .Values.logs.enabled (or .Values.logs.podLogsObjects.enabled .Values.receivers.grpc.enabled .Values.receivers.http.enabled) }}
    {{- if .Values.logs.podLogsObjects.enabled }}
      {{- include "alloy.config.pod_log_objects" . }}
    {{- end }}

    {{- include "alloy.config.logs.pod_logs_processor" . }}
    {{- include "alloy.config.logsService" . }}
  {{- end }}

  {{- if and .Values.traces.enabled }}
    {{- include "alloy.config.tracesService" . }}
  {{- end }}

  {{- include "alloy.config.logging" .Values.alloy.logging}}

  {{- if .Values.extraConfig }}
    {{- tpl .Values.extraConfig . | indent 0 }}
  {{- end }}
{{- end -}}

{{/* Grafana Alloy for Events config */}}
{{- define "alloyEventsConfig" -}}
  {{- include "alloy.config.logs.cluster_events" . }}
  {{- include "alloy.config.logsService" . }}
  {{- include "alloy.config.logging" (index .Values "alloy-events").logging }}

  {{- if .Values.logs.cluster_events.extraConfig }}
    {{- tpl .Values.logs.cluster_events.extraConfig . | indent 0 }}
  {{- end }}
{{- end -}}

{{/* Grafana Alloy for Logs config */}}
{{- define "alloyLogsConfig" -}}
  {{- include "alloy.config.logs.pod_logs_discovery" . }}
  {{- include "alloy.config.logs.pod_logs_processor" . }}
  {{- include "alloy.config.logsService" . }}

  {{- include "alloy.config.logging" (index .Values "alloy-logs").logging }}

  {{- if .Values.logs.extraConfig }}
    {{- tpl .Values.logs.extraConfig . | indent 0 }}
  {{- end }}
{{- end -}}

{{/* Grafana Alloy for Profiles config */}}
{{- define "alloyProfilesConfig" -}}
  {{- include "alloy.config.profilesEbpf" . }}
  {{- include "alloy.config.profilesPprof" . }}

  {{- include "alloy.config.profilesService" . }}
  {{- include "alloy.config.logging" (index .Values "alloy-profiles").logging }}
{{- end -}}
