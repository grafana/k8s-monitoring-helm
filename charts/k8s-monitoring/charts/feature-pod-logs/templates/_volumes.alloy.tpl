{{- define "feature.podLogs.volumes.alloy" }}
discovery.kubernetes "pods" {
  role = "pod"
  selectors {
    role = "pod"
    field = "spec.nodeName=" + sys.env("HOSTNAME")
  }
{{- if .Values.namespaces }}
  namespaces {
    names = {{ .Values.namespaces | toJson }}
  }
{{- end }}
}

discovery.relabel "filtered_pods_with_paths" {
  targets = discovery.relabel.filtered_pods.output

  rule {
    source_labels = ["__meta_kubernetes_pod_uid", "__meta_kubernetes_pod_container_name"]
    separator = "/"
    action = "replace"
    replacement = "/var/log/pods/*$1/*.log"
    target_label = "__path__"
  }
}

local.file_match "pod_logs" {
  path_targets = discovery.relabel.filtered_pods_with_paths.output
}

loki.source.file "pod_logs" {
  targets    = local.file_match.pod_logs.targets
{{- if .Values.volumeGatherSettings.onlyGatherNewLogLines }}
  tail_from_end = {{ .Values.volumeGatherSettings.onlyGatherNewLogLines }}
{{- end }}
  forward_to = [loki.process.pod_logs.receiver]
}
{{- end -}}