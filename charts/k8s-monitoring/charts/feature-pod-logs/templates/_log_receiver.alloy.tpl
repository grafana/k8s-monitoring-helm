{{- define "feature.podLogs.lokiReceiver.alloy" }}
loki.source.api "loki_receiver" {
  http {
    listen_address = "0.0.0.0"
    listen_port = {{ .Values.lokiReceiver.port }}
  }

{{- if .Values.openShiftClusterLogForwarder.enabled }}
  forward_to = [loki.process.openshift_logs.receiver]
}

loki.process "openshift_logs"  {

  stage.json {}

  stage.match {
    selector = "{log_type=\"application\"}"
    stage.labels {
      pod = "kubernetes_pod_name"
      namespace = "kubernetes_namespace"
      container = "kubernetes_container_name"
      node = "hostname"
    }
    stage.template {
      source   = "job"
      template = "{{ "{{" }} .namespace {{ "}}" }}/{{ "{{" }} .container {{ "}}" }}"
    }
  }

  stage.match {
    selector = "{log_type=\"infrastructure\"}"
    stage.labels {
      pod = "kubernetes_pod_name"
      namespace = "kubernetes_namespace"
      container = "kubernetes_container_name"
      node = "hostname"
    }
    stage.static_labels {
      job = "integrations/node_logs"
    }
    stage.template {
      source   = "job"
      template = "{{ "{{" }} .namespace {{ "}}" }}/{{ "{{" }} .container {{ "}}" }}"
    }
  }

{{- end }}
  forward_to = [loki.process.pod_log_processor.receiver]
}
{{- end }}
