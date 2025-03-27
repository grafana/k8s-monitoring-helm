{{/* Validates that the Alloy instance is appropriate for the given Pod Logs settings */}}
{{/* Inputs: Values (Pod Logs values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.podLogs.collector.validate" -}}
{{- $stabilityLevel := (dig "alloy" "stabilityLevel" "generally-available" .Collector)}}
{{- if eq .Values.gatherMethod "volumes" }}
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
{{- else if eq .Values.gatherMethod "kubernetesApi" }}
  {{- if or .Collector.alloy.mounts.varlog .Collector.alloy.mounts.dockercontainers }}
    {{- $msg := list "" }}
    {{- if and .Collector.alloy.mounts.varlog (not .Collector.alloy.mounts.dockercontainers) }}
      {{- $msg = append $msg "Pod Logs feature should not mount /var/log when using the \"kubernetesApi\" gather method." }}
    {{- else if and (not .Collector.alloy.mounts.varlog) .Collector.alloy.mounts.dockercontainers }}
      {{- $msg = append $msg "Pod Logs feature should not mount /var/lib/docker/containers when using the \"kubernetesApi\" gather method." }}
    {{- else if and .Collector.alloy.mounts.varlog .Collector.alloy.mounts.dockercontainers }}
      {{- $msg = append $msg "Pod Logs feature should not mount /var/log or /var/lib/docker/containers when using the \"kubernetesApi\" gather method." }}
    {{- end -}}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    mounts:"}}
    {{- if and .Collector.alloy.mounts.varlog }}
      {{- $msg = append $msg "      varlog: false" }}
    {{- end -}}
    {{- if .Collector.alloy.mounts.dockercontainers }}
      {{- $msg = append $msg "      dockercontainers: false" }}
    {{- end -}}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
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
{{- else if eq .Values.gatherMethod "filelog" }}
  {{- if and (ne $stabilityLevel "public-preview") (ne $stabilityLevel "experimental") }}
    {{- $msg := list "" "Pod Logs feature requires Alloy to use the public-preview stability level when using the \"filelog\" gather method." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    stabilityLevel: public-preview"}}
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
