{{/* Validates that the Alloy instance is appropriate for the given Node Logs settings */}}
{{/* Inputs: Values (Node Logs values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.nodeLogs.collector.validate" -}}
{{- if not (eq .Collector.controller.type "daemonset") }}
  {{- fail (printf "Node Logs feature requires Alloy to be a DaemonSet.\nPlease set:\n%s:\n  controller:\n    type: daemonset" .CollectorName) }}
{{- end -}}
{{- if and (hasPrefix "/var/log" .Values.journal.path) (not .Collector.alloy.mounts.varlog) }}
  {{- fail (printf "Node Logs feature requires Alloy to mount /var/log.\nPlease set:\n%s:\n  alloy:\n    mounts:\n      varlog: true" .CollectorName) }}
{{- end -}}
{{- if .Collector.alloy.clustering.enabled }}
  {{- fail (printf "Node Logs feature requires Alloy clustering to be disabled.\nPlease set:\n%s:\n  alloy:\n    clustering:\n      enabled: false" .CollectorName) }}
{{- end -}}
{{- end -}}
