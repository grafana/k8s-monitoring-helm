{{- define "feature.podLogsViaOpenTelemetry.module" }}
declare "pod_logs_via_opentelemetry" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
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
    start_at = {{ if .Values.onlyGatherNewLogLines }}"end"{{ else }}"beginning"{{ end }}
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
  } // otelcol.receiver.filelog "pod_logs"

  otelcol.processor.k8sattributes "pod_logs" {
    pod_association {
      source {
        from = "resource_attribute"
        name = "k8s.pod.uid"
      }
    }

    extract {
      otel_annotations = {{ .Values.otelAnnotations }}
      metadata = [
        "k8s.deployment.name",
        "k8s.statefulset.name",
        "k8s.daemonset.name",
        "k8s.cronjob.name",
        "k8s.job.name",
        "k8s.node.name",
      ]
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
{{- range $attribute, $value := .Values.staticAttributes }}
        `set(attributes[{{ $attribute | quote }}], {{ $value | quote }})`,
{{- end }}
{{- range $attribute, $value := .Values.staticAttributesFrom }}
        `set(attributes[{{ $attribute | quote }}], {{ $value }})`,
{{- end }}
      ]
    }

    log_statements {
      context = "log"
      statements = [
        `delete_key(attributes, "log.file.path")`,
      ]
    }

    output {
      logs = argument.logs_destinations.value
    }
  } // otelcol.processor.transform "pod_logs"
} // declare "pod_logs_via_opentelemetry"
{{- end -}}
