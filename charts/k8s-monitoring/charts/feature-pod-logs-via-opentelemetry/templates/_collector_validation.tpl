{{/* Validates that the Alloy instance is appropriate for the given Pod Logs settings */}}
{{/* Inputs: Values (Pod Logs values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.podLogsViaOpenTelemetry.collector.validate" }}
  {{- if ne (dig "controller" "type" "daemonset" .Collector) "daemonset" }}
    {{- $msg := list "" "Pod Logs feature requires Alloy to be a DaemonSet." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  presets: [daemonset]"}}
    {{- $msg = append $msg "OR"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  controller:"}}
    {{- $msg = append $msg "    type: daemonset" }}
    {{- fail (join "\n" $msg) }}
  {{- end -}}

  {{- if (not (dig "alloy" "mounts" "varlog" false .Collector)) }}
    {{- $msg := list "" "Pod Logs feature requires Alloy to mount /var/log." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  presets: [filesystem-log-reader]"}}
    {{- $msg = append $msg "OR"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    mounts:"}}
    {{- $msg = append $msg "      varlog: true" }}
    {{- fail (join "\n" $msg) }}
  {{- end -}}

  {{- $stabilityLevel := (dig "alloy" "stabilityLevel" "generally-available" .Collector)}}
  {{- if and (ne $stabilityLevel "public-preview") (ne $stabilityLevel "experimental") }}
    {{- $msg := list "" "Pod Logs feature requires Alloy to use the public-preview stability level." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    stabilityLevel: public-preview"}}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
{{- end -}}
