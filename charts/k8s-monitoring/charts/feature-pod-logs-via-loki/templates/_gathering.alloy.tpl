
{{- define "feature.podLogsViaLoki.gathering.alloy" }}
local.file_match "pod_logs" {
  path_targets = discovery.relabel.filtered_pods.output
}

loki.source.file "pod_logs" {
  targets    = local.file_match.pod_logs.targets
{{- if .Values.onlyGatherNewLogLines }}
  tail_from_end = {{ .Values.onlyGatherNewLogLines }}
{{- end }}
  forward_to = [loki.process.pod_logs.receiver]
}
{{- end -}}
