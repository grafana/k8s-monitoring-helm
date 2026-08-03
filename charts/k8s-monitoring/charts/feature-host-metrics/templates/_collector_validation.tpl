{{/* Validates that the Alloy instance is appropriate for the given Host Metrics settings */}}
{{/* Inputs: Values (Host Metrics values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.hostMetrics.linuxHosts.collector.validate" }}
  {{- if and .Values.linuxHosts.enabled (eq (.Values.linuxHosts.source | default "node-exporter") "alloy") }}
    {{- if ne (dig "controller" "type" "daemonset" .Collector) "daemonset" }}
      {{- $msg := list "" "Collecting Linux host metrics with Alloy (hostMetrics.linuxHosts.source: alloy) requires Alloy to be a DaemonSet." }}
      {{- $msg = append $msg "Please set:"}}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .CollectorName) }}
      {{- $msg = append $msg "    presets: [linux-host-monitor, daemonset]"}}
      {{- fail (join "\n" $msg) }}
    {{- end -}}

    {{- $hasHostRootMount := false }}
    {{- range (dig "alloy" "mounts" "extra" list .Collector) }}
      {{- if eq (.mountPath | default "") "/host/root" }}
        {{- $hasHostRootMount = true }}
      {{- end }}
    {{- end }}
    {{- if not $hasHostRootMount }}
      {{- $msg := list "" "Collecting Linux host metrics with Alloy (hostMetrics.linuxHosts.source: alloy) requires Alloy to mount the host filesystem at /host/root." }}
      {{- $msg = append $msg "Please set:"}}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .CollectorName) }}
      {{- $msg = append $msg "    presets: [linux-host-monitor, daemonset]"}}
      {{- fail (join "\n" $msg) }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Validates that the Alloy instance is appropriate for the given Host Metrics settings */}}
{{/* Inputs: Values (Host Metrics values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.hostMetrics.windowsHosts.collector.validate" }}
  {{- if and .Values.windowsHosts.enabled (eq (.Values.windowsHosts.source | default "windows-exporter") "alloy") }}
    {{- if ne (dig "controller" "type" "daemonset" .Collector) "daemonset" }}
      {{- $msg := list "" "Collecting Windows host metrics with Alloy (hostMetrics.windowsHosts.source: alloy) requires Alloy to be a DaemonSet running on Windows nodes." }}
      {{- $msg = append $msg "Please set:"}}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .CollectorName) }}
      {{- $msg = append $msg "    presets: [windows, daemonset]"}}
      {{- fail (join "\n" $msg) }}
    {{- end -}}

    {{- if ne (dig "controller" "nodeSelector" "kubernetes.io/os" "" .Collector) "windows" }}
      {{- $msg := list "" "Collecting Windows host metrics with Alloy (hostMetrics.windowsHosts.source: alloy) requires Alloy to be scheduled onto Windows nodes." }}
      {{- $msg = append $msg "Please set:"}}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .CollectorName) }}
      {{- $msg = append $msg "    presets: [windows, daemonset]"}}
      {{- fail (join "\n" $msg) }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* Validates that the Alloy instance is appropriate for the given Host Metrics settings */}}
{{/* Inputs: Values (Host Metrics values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.hostMetrics.collector.validate" }}
  {{- include "feature.hostMetrics.linuxHosts.collector.validate" . }}
  {{- include "feature.hostMetrics.windowsHosts.collector.validate" . }}
{{- end -}}
