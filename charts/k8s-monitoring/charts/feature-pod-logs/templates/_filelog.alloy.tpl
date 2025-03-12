{{- define "feature.podLogs.filelog.alloy" }}
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
  start_at = {{ if .Values.filelogGatherSettings.onlyGatherNewLogLines }}"end"{{ else }}"beginning"{{ end }}
  include_file_name = false
  include_file_path = true

  operators = [
    // Container operator will set k8s.pod.name, k8s.pod.uid, k8s.container.name, k8s.container.restart_count, and k8s.namespace.name
    {
      type                       = "container",
      add_metadata_from_filepath = true,
    },
  ]

  output {
    logs = [otelcol.processor.k8sattributes.pod_logs.input]
  }
}

otelcol.processor.k8sattributes "pod_logs" {
  pod_association {
    source {
      from = "resource_attribute"
      name = "k8s.pod.uid"
    }
  }

  extract {
    metadata = [
      "k8s.deployment.name",
      "k8s.statefulset.name",
      "k8s.daemonset.name",
      "k8s.cronjob.name",
      "k8s.job.name",
      "k8s.node.name",
    ]
    annotation {
      key_regex = "(.*)"
      tag_name  = "$1"
      from      = "pod"
    }
    annotation {
      key_regex = "resource.opentelemetry.io/(.*)"
      tag_name  = "$1"
      from      = "pod"
    }
{{- range $attribute, $annotation := .Values.annotations }}
    annotation {
      tag_name = {{ $attribute | quote }}
      key      = {{ $annotation | quote }}
      from     = "pod"
    }
{{- end }}
{{- range $attribute, $annotation := .Values.nodeAnnotations }}
    annotation {
      tag_name = {{ $attribute | quote }}
      key      = {{ $annotation | quote }}
      from     = "node"
    }
{{- end }}
{{- range $attribute, $annotation := .Values.namespaceAnnotations }}
    annotation {
      tag_name = {{ $attribute | quote }}
      key      = {{ $annotation | quote }}
      from     = "namespace"
    }
{{- end }}
    label {
      key_regex = "(.*)"
      tag_name  = "$1"
      from      = "pod"
    }
{{- range $attribute, $label := .Values.labels }}
    label {
      tag_name = {{ $attribute | quote }}
      key      = {{ $label | quote }}
      from     = "pod"
    }
{{- end }}
{{- range $attribute, $label := .Values.nodeLabels }}
    label {
      tag_name = {{ $attribute | quote }}
      key      = {{ $label | quote }}
      from     = "node"
    }
{{- end }}
{{- range $attribute, $label := .Values.namespaceLabels }}
    label {
      tag_name = {{ $attribute | quote }}
      key      = {{ $label | quote }}
      from     = "namespace"
    }
{{- end }}
  }

  output {
    logs = [otelcol.processor.transform.pod_logs.input]
  }
}

otelcol.processor.transform "pod_logs" {
  error_mode = "ignore"
  log_statements {
    context = "resource"
    statements = [
      `delete_key(attributes, "k8s.container.restart_count")`,
      `delete_key(attributes, "log.file.path")`,

      `set(attributes["service.name"], attributes["app.kubernetes.io/name"]) where attributes["service.name"] == nil`,
      `set(attributes["service.name"], attributes["k8s.deployment.name"]) where attributes["service.name"] == nil`,
      `set(attributes["service.name"], attributes["k8s.replicaset.name"]) where attributes["service.name"] == nil`,
      `set(attributes["service.name"], attributes["k8s.statefulset.name"]) where attributes["service.name"] == nil`,
      `set(attributes["service.name"], attributes["k8s.daemonset.name"]) where attributes["service.name"] == nil`,
      `set(attributes["service.name"], attributes["k8s.cronjob.name"]) where attributes["service.name"] == nil`,
      `set(attributes["service.name"], attributes["k8s.job.name"]) where attributes["service.name"] == nil`,
      `set(attributes["service.name"], attributes["k8s.pod.name"]) where attributes["service.name"] == nil`,
      `set(attributes["service.name"], attributes["k8s.container.name"]) where attributes["service.name"] == nil`,

      `set(attributes["service.namespace"], attributes["k8s.namespace.name"]) where attributes["service.namespace"] == nil`,

      `set(attributes["service.version"], attributes["app.kubernetes.io/version"]) where attributes["service.version"] == nil`,

      `set(attributes["service.instance.id"], Concat([attributes["k8s.namespace.name"], attributes["k8s.pod.name"], attributes["k8s.container.name"]], ".")) where attributes["service.instance.id"] == nil`,

      `set(attributes["loki.resource.labels"], {{ .Values.labelsToKeep | join "," | quote }})`,   // Used to preserve the labels when converting to Loki
      `keep_matching_keys(attributes, "loki.resource.labels|{{ .Values.labelsToKeep | join "|" }}")`,
    ]
  }

  output {
    logs = [otelcol.exporter.loki.pod_logs.input]
  }
}

otelcol.exporter.loki "pod_logs" {
  forward_to = [loki.process.pod_logs.receiver]
}
{{- end -}}
