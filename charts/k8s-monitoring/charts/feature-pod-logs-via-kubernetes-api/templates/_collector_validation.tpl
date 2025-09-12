{{/* Validates that the Alloy instance is appropriate for the given Pod Logs via Kubernetes API settings */}}
{{/* Inputs: Values (feature values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.podLogsViaKubernetesApi.collector.validate" -}}
{{- $stabilityLevel := (dig "alloy" "stabilityLevel" "generally-available" .Collector)}}
{{- if not (dig "alloy" "clustering" "enabled" false .Collector) }}
  {{- if eq (dig "controller" "type" "daemonset" .Collector) "daemonset" }}
    {{- $msg := list "" "Pod Logs feature requires Alloy DaemonSet to be in clustering mode when using the \"kubernetesApi\" gather method." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    clustering:"}}
    {{- $msg = append $msg "      enabled: true" }}
    {{- fail (join "\n" $msg) }}
  {{- else if gt ((dig "controller" "replicas" 1 .Collector) | int) 1 }}
    {{- $msg := list "" "Pod Logs feature requires Alloy with multiple replicas to be in clustering mode when using the \"kubernetesApi\" gather method." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    clustering:"}}
    {{- $msg = append $msg "      enabled: true" }}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
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
