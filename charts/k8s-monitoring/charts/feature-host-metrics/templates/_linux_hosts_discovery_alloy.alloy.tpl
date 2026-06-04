{{- define "feature.hostMetrics.linuxHosts.discovery.viaAlloy" }}

prometheus.exporter.unix "node_exporter" {
  rootfs_path = "/host/root"
  procfs_path = "/host/proc"
  sysfs_path  = "/host/sys"
} // prometheus.exporter.unix "node_exporter"

discovery.relabel "node_exporter" {
  targets = prometheus.exporter.unix.node_exporter.targets

  // Set the instance label to the node name
  rule {
    target_label = "instance"
    replacement = sys.env("NODE_NAME")
  }

  // Override the job label set by prometheus.exporter.unix to match the Node Exporter source
  rule {
    target_label = "job"
    replacement = {{ .Values.linuxHosts.jobLabel | quote }}
  }

  rule {
    target_label = "source"
    replacement = "kubernetes"
  }
{{- if .Values.linuxHosts.extraDiscoveryRules }}
  {{- .Values.linuxHosts.extraDiscoveryRules | nindent 2 }}
{{- end }}
} // discovery.relabel "node_exporter"
{{- end }}
