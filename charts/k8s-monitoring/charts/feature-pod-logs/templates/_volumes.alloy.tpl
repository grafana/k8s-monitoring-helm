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

otelcol.receiver.filelog "pod_logs" {
{{- if .Values.namespaces }}
  include = [
{{- range .Values.namespaces }}
    "/var/log/pods/{{ . }}_*/*/*.log",
{{- end }}
  ]
{{- else }}
  include = ["/var/log/pods/*/*/*.log"]
{{- end }}
{{- if .Values.excludeNamespaces }}
  exclude = [
{{- range .Values.excludeNamespaces }}
    "/var/log/pods/{{ . }}_*/*/*.log",
{{- end }}
  ]
{{- end }}
  start_at = {{ if .Values.volumeGatherSettings.onlyGatherNewLogLines }}"end"{{ else }}"beginning"{{ end }}
  include_file_name = false
  include_file_path = true

  operators = [
    {
      type = "container",
    },
  ]

  output {
    logs = [otelcol.processor.k8sattributes.pod_logs.input]
  }
}

otelcol.processor.k8sattributes "pod_logs" {
  extract {
    metadata = [
      "k8s.namespace.name",
      "k8s.pod.name",
      "k8s.deployment.name",
      "k8s.statefulset.name",
      "k8s.daemonset.name",
      "k8s.cronjob.name",
      "k8s.job.name",
      "k8s.node.name",
    ]
  }
  pod_association {
    source {
      from = "resource_attribute"
      name = "k8s.pod.uid"
    }
  }

  output {
    logs = [otelcol.processor.attributes.pod_logs.input]
  }
}

otelcol.processor.attributes "pod_logs" {
//  action {
//    key = "loki.attribute.labels"
//    action = "insert"
//    value = "k8s.namespace.name,k8s.pod.name,k8s.deployment.name,k8s.statefulset.name,k8s.daemonset.name,k8s.cronjob.name,k8s.job.name,k8s.node.name"
//  }
//  action {
//    key = "loki.resource.labels"
//    action = "insert"
//    value = "k8s.namespace.name,k8s.pod.name,k8s.deployment.name,k8s.statefulset.name,k8s.daemonset.name,k8s.cronjob.name,k8s.job.name,k8s.node.name"
//  }

  output {
    logs = [otelcol.exporter.loki.pod_logs.input]
  }
}

otelcol.exporter.loki "pod_logs" {
  forward_to = [loki.process.pod_logs.receiver]
}
{{- end -}}
