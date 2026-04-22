
{{- define "feature.podLogsViaLoki.gathering.alloy" }}
local.file_match "pod_logs" {
  path_targets = discovery.relabel.filtered_pods.output
} // local.file_match "pod_logs"

loki.source.file "pod_logs" {
  targets    = local.file_match.pod_logs.targets
  tail_from_end = {{ .Values.onlyGatherNewLogLines }}
  forward_to = [loki.process.pod_logs.receiver]
} // loki.source.file "pod_logs"
{{- end -}}
