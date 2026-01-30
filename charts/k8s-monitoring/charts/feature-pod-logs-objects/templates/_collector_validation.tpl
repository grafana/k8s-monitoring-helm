{{/* Validates that the Alloy instance is appropriate for the given PodLogs Objects settings */}}
{{/* Inputs: Values (PodLogs Objects values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.podLogsObjects.collector.validate" -}}
{{- if not (dig "alloy" "clustering" "enabled" false .Collector) }}
  {{- if eq (dig "controller" "type" "daemonset" .Collector) "daemonset" }}
    {{- $msg := list "" "PodLogs Objects feature requires Alloy DaemonSet to be in clustering mode." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    clustering:"}}
    {{- $msg = append $msg "      enabled: true" }}
    {{- fail (join "\n" $msg) }}
  {{- else if gt ((dig "controller" "replicas" 1 .Collector) | int) 1 }}
    {{- $msg := list "" "PodLogs Objects feature requires Alloy with multiple replicas to be in clustering mode." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    clustering:"}}
    {{- $msg = append $msg "      enabled: true" }}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
{{- end -}}

{{- if .Values.nodeFilter }}
  {{- if ne (dig "controller" "type" "daemonset" .Collector) "daemonset" }}
    {{- $msg := list "" "PodLogs Objects feature requires Alloy to be a DaemonSet when using nodeFilter." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  controller:"}}
    {{- $msg = append $msg "    type: daemonset"}}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
{{- end -}}

{{- if .Values.secretFilter.enabled }}
  {{- $stabilityLevel := (dig "alloy" "stabilityLevel" "generally-available" .Collector)}}
  {{- if ne $stabilityLevel "experimental" }}
    {{- $msg := list "" "PodLogs Objects feature requires Alloy to use the experimental stability level when using the secretFilter." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    stabilityLevel: experimental"}}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
{{- end -}}
{{- end -}}
