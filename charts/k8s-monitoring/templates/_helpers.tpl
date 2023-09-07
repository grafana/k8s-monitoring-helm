{{/* This template checks that the port defined in .Values.traces.receiver.port is in the targetPort list on .grafana-agent */}}
{{- define "checkForTracePort" -}}
  {{- $tracePort := .Values.traces.receiver.port -}}
  {{- $found := false -}}
  {{- range (index .Values "grafana-agent").agent.extraPorts -}}
    {{- if eq .targetPort $tracePort }}
      {{- $found = true -}}
      {{- break -}}
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
