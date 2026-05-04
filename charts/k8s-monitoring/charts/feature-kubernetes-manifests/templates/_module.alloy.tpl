{{- define "feature.kubernetesManifests.module" }}
declare "kubernetes_manifests" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  discovery.kubernetes "manifest_tail" {
    role = "pod"
    selectors {
      role = "pod"
      label = "app.kubernetes.io/name=k8s-manifest-tail"
    }
  } // discovery.kubernetes "manifest_tail"

  loki.source.kubernetes "manifest_tail" {
    targets    = discovery.kubernetes.manifest_tail.targets
    clustering {
      enabled = true
    }
    forward_to = [loki.process.manifest_tail.receiver]
  } // loki.source.kubernetes "manifest_tail"

  loki.process "manifest_tail" {
    stage.static_labels {
      values = {
        "job" = {{ .Values.jobLabel | quote }},
      }
    }

    stage.json {
      expressions = {
        "body_value" = "Body.Value",
        "action" = "Attributes[?Key=='action'].Value.Value | [0]",
        "k8s.namespace.name" = "Attributes[?Key=='k8s.namespace.name'].Value.Value | [0]",
{{- range (dig "k8s-manifest-tail" "config" "objects" (list) .telemetryServices) }}
        "k8s.{{ .kind | lower }}.name" = "Attributes[?Key=='k8s.{{ .kind | lower }}.name'].Value.Value | [0]",
{{- end }}
      }
    }

    stage.json {
      source = "body_value"
      expressions = {
        "kind" = "",
      }
    }

    stage.labels {
      values = {
        "action"             = "action",
        "k8s_kind"           = "kind",
        "k8s_namespace_name" = "k8s.namespace.name",
      }
    }

    stage.match {
      selector = "{action=\"manifest\"}"
      stage.output {
        source = "body_value"
      }
    }

    stage.match {
      selector = "{action=\"deleted\"}"
      stage.template {
        source   = "empty_body"
        template = "DELETED"
      }
      stage.output {
        source = "empty_body"
      }
    }

    stage.match {
      selector = "{action=\"created\"}"
      stage.template {
        source   = "empty_body"
        template = "CREATED"
      }
      stage.output {
        source = "empty_body"
      }
    }

    stage.match {
      selector = "{action=\"modified\"}"
      stage.json {
        source = "body_value"
        expressions = {
          "previous" = "",
          "current"  = "",
        }
      }
      stage.template {
        source   = "modified_body"
        template = "{\"previous\": {{ "{{" }} if .previous {{ "}}" }}{{ "{{" }} .previous {{ "}}" }}{{ "{{" }} else {{ "}}" }}null{{ "{{" }} end {{ "}}" }}, \"current\": {{ "{{" }} .current {{ "}}" }}}"
      }
      stage.output {
        source = "modified_body"
      }
    }

    stage.structured_metadata {
      values = {
{{- range (dig "k8s-manifest-tail" "config" "objects" (list) .telemetryServices) }}
        "k8s_{{ .kind | lower }}_name" = "k8s.{{ .kind | lower }}.name",
{{- end }}
      }
    }

    forward_to = argument.logs_destinations.value
  } // loki.process "manifest_tail"
} // declare "kubernetes_manifests"
{{- end -}}
