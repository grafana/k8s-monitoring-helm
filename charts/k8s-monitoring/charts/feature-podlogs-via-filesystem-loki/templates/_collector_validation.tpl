{{/* Validates that the Alloy instance is appropriate for the given Pod Logs settings */}}
{{/* Inputs: Values (Pod Logs values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.podLogs.collector.validate" -}}
{{- $stabilityLevel := (dig "alloy" "stabilityLevel" "generally-available" .Collector)}}
{{- if ne (dig "controller" "type" "daemonset" .Collector) "daemonset" }}
  {{- $msg := list "" "Pod Logs feature requires Alloy to be a DaemonSet when using the \"volumes\" gather method." }}
  {{- $msg = append $msg "Please set:"}}
  {{- $msg = append $msg (printf "%s:" .CollectorName) }}
  {{- $msg = append $msg "  controller:"}}
  {{- $msg = append $msg "    type: daemonset" }}
  {{- fail (join "\n" $msg) }}
{{- end -}}
{{- if (not (dig "alloy" "mounts" "varlog" false .Collector)) }}
  {{- $msg := list "" "Pod Logs feature requires Alloy to mount /var/log when using the \"volumes\" gather method." }}
  {{- $msg = append $msg "Please set:"}}
  {{- $msg = append $msg (printf "%s:" .CollectorName) }}
  {{- $msg = append $msg "  alloy:"}}
  {{- $msg = append $msg "    mounts:"}}
  {{- $msg = append $msg "      varlog: true" }}
  {{- fail (join "\n" $msg) }}
{{- end -}}

{{- if .Values.secretFilter.enabled }}
  {{- if ne $stabilityLevel "experimental" }}
    {{- $msg := list "" "Pod Logs feature requires Alloy to use the experimental stability level when using the secretFilter." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    stabilityLevel: experimental"}}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
{{- end -}}
{{- end -}}
