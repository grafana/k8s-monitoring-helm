{{/* This template checks that the port defined in .Values.traces.receiver.port is in the targetPort list on .grafana-agent */}}
{{- define "checkForTracePort" -}}
  {{- $tracePort := .Values.traces.receiver.port -}}
  {{- $found := false -}}
  {{- range (index .Values "grafana-agent").agent.extraPorts -}}
    {{- if eq .targetPort $tracePort }}
      {{- $found = true -}}
    {{- end }}
  {{- end }}
  {{- if not $found }}
    {{- fail (print
    "Trace port not opened on the Grafana Agent.\n"
    "In order for traces to work, the " $tracePort " port needs to be opened on the Grafana Agent. For example, set this in your values file:\n"
    "grafana-agent:\n"
    "  agent:\n"
    "    extraPorts:\n"
    "      - name: \"otlp-traces\"\n"
    "        port: " $tracePort "\n"
    "        targetPort: " $tracePort "\n"
    "        protocol: \"TCP\"\n"
    "For more examples, see https://github.com/grafana/k8s-monitoring-helm/tree/main/examples/traces-enabled") -}}
  {{- end -}}
{{- end -}}

{{/* Grafana Agent config */}}
{{- define "agentConfig" -}}
{{- include "agent.config.nodes" . }}
{{- include "agent.config.pods" . }}
{{- include "agent.config.services" . }}

{{- if .Values.metrics.enabled }}
  {{- include "agent.config.agent" . }}

  {{- if .Values.metrics.kubelet.enabled }}
    {{- include "agent.config.kubelet" . }}
  {{- end }}

  {{- if .Values.metrics.cadvisor.enabled }}
    {{- include "agent.config.cadvisor" . }}
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

  {{- include "agent.config.prometheus" . }}
{{- end }}

{{- if and .Values.logs.enabled .Values.logs.cluster_events.enabled }}
  {{- include "agent.config.logs.cluster_events" . }}
  {{- include "agent.config.loki" . }}
{{- end }}

{{- if and .Values.traces.enabled }}
  {{- include "agent.config.traces" . }}
  {{- include "agent.config.tempo" . }}
{{- end }}

{{- if .Values.extraConfig }}
  {{- .Values.extraConfig }}
{{ end }}
{{- end -}}

{{/* Grafana Agent Logs config */}}
{{- define "agentLogsConfig" -}}
{{- include "agent.config.pods" . }}
{{- include "agent.config.logs.pod_logs" . }}
{{- include "agent.config.loki" . }}
{{- if .Values.logs.extraConfig }}
  {{- .Values.logs.extraConfig }}
{{ end }}
{{- end -}}
