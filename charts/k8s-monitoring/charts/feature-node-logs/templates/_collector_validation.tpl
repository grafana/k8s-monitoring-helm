{{/* Validates that the Alloy instance is appropriate for the given Node Logs settings */}}
{{/* Inputs: Values (Node Logs values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.nodeLogs.collector.validate" -}}
{{- if not (eq .Collector.controller.type "daemonset") }}
  {{- $msg := list "" "Node Logs feature requires Alloy to be a DaemonSet." }}
  {{- $msg = append $msg "Please set:"}}
  {{- $msg = append $msg (printf "%s:" .CollectorName) }}
  {{- $msg = append $msg "  controller:"}}
  {{- $msg = append $msg "    type: daemonset" }}
  {{- fail (join "\n" $msg) }}
{{- end -}}
{{- if and (hasPrefix "/var/log" .Values.journal.path) (not .Collector.alloy.mounts.varlog) }}
  {{- $msg := list "" "Node Logs feature requires Alloy to mount /var/log." }}
  {{- $msg = append $msg "Please set:"}}
  {{- $msg = append $msg (printf "%s:" .CollectorName) }}
  {{- $msg = append $msg "  alloy:"}}
  {{- $msg = append $msg "    mounts:"}}
  {{- $msg = append $msg "      varlog: true" }}
  {{- fail (join "\n" $msg) }}
{{- end -}}
{{- end -}}
