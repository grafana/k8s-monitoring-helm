{{/* Validates that the Alloy instance is appropriate for the given Pod Logs settings */}}
{{/* Inputs: Values (Pod Logs values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.podLogs.collector.validate" -}}
{{- if eq .Values.gatherMethod "volumes" }}
  {{- if not (eq .Collector.controller.type "daemonset") }}
    {{- $msg := list "" "Pod Logs feature requires Alloy to be a DaemonSet when using the \"volumes\" gather method." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  controller:"}}
    {{- $msg = append $msg "    type: daemonset" }}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
  {{- if not .Collector.alloy.mounts.varlog }}
    {{- $msg := list "" "Pod Logs feature requires Alloy to mount /var/log when using the \"volumes\" gather method." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    mounts:"}}
    {{- $msg = append $msg "      varlog: true" }}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
  {{- if .Collector.alloy.clustering.enabled }}
    {{- $msg := list "" "Pod Logs feature requires Alloy clustering to be disabled when using the \"volumes\" gather method." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    clustering:"}}
    {{- $msg = append $msg "      enabled: false" }}
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
  {{- if not .Collector.alloy.clustering.enabled }}
    {{- if eq .Collector.controller.type "daemonset" }}
      {{- $msg := list "" "Pod Logs feature requires Alloy DaemonSet to be in clustering mode when using the \"kubernetesApi\" gather method." }}
      {{- $msg = append $msg "Please set:"}}
      {{- $msg = append $msg (printf "%s:" .CollectorName) }}
      {{- $msg = append $msg "  alloy:"}}
      {{- $msg = append $msg "    clustering:"}}
      {{- $msg = append $msg "      enabled: true" }}
      {{- fail (join "\n" $msg) }}
    {{- else if gt (.Collector.controller.replicas | int) 1 }}
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
  {{- if and (not (eq .Collector.alloy.stabilityLevel "public-preview")) (not (eq .Collector.alloy.stabilityLevel "experimental")) }}
    {{- $msg := list "" "Pod Logs feature requires Alloy to use the public-preview stability level when using the \"filelog\" gather method." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    stabilityLevel: public-preview"}}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
{{- end -}}

{{- if .Values.secretFilter.enabled }}
  {{- if not (eq .Collector.alloy.stabilityLevel "experimental") }}
    {{- $msg := list "" "Pod Logs feature requires Alloy to use the experimental stability level when using the secretFilter." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    stabilityLevel: experimental"}}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
{{- end -}}
{{- end -}}
