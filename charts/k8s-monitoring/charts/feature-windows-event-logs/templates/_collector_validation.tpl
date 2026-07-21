{{/* Validates that the Alloy instance is appropriate for the given Windows Event Logs settings */}}
{{/* Inputs: Values (Windows Event Logs values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.windowsEventLogs.collector.validate" -}}
{{- if not (eq .Collector.controller.type "daemonset") }}
  {{- $msg := list "" "Windows Event Logs feature requires Alloy to be a DaemonSet, so that an Alloy Pod runs on every Windows Node." }}
  {{- $msg = append $msg "Please set:"}}
  {{- $msg = append $msg "collectors:" }}
  {{- $msg = append $msg (printf "  %s:" .CollectorName) }}
  {{- $msg = append $msg "    controller:"}}
  {{- $msg = append $msg "      type: daemonset" }}
  {{- fail (join "\n" $msg) }}
{{- end -}}
{{- if not (has "windows" (.Collector.presets | default list)) }}
  {{- $msg := list "" "Windows Event Logs feature requires Alloy to use the `windows` preset, so it runs as a HostProcess container on Windows Nodes." }}
  {{- $msg = append $msg "Please set:"}}
  {{- $msg = append $msg "collectors:" }}
  {{- $msg = append $msg (printf "  %s:" .CollectorName) }}
  {{- $msg = append $msg "    presets: [windows, daemonset]"}}
  {{- fail (join "\n" $msg) }}
{{- end -}}
{{- end -}}
