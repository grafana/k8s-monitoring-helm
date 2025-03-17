{{- define "feature.clusterEvents.module" }}
declare "cluster_events" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  loki.source.kubernetes_events "cluster_events" {
    job_name   = "integrations/kubernetes/eventhandler"
    log_format = "{{ .Values.logFormat }}"
  {{- if .Values.namespaces }}
    namespaces = {{ .Values.namespaces | toJson }}
  {{- end }}
    forward_to = [loki.process.cluster_events.receiver]
  }

  loki.process "cluster_events" {
    {{- if .Values.excludeNamespaces }}
    stage.drop {
      source = "namespace"
      expression = {{ .Values.excludeNamespaces | join "|" | quote }}
      drop_counter_reason = "excluded_namespaces"
    }
    {{- end }}

    // add a static source label to the logs so they can be differentiated / restricted if necessary
    stage.static_labels {
      values = {
        "source" = "kubernetes-events",
      }
    }

    // extract some of the fields from the log line, these could be used as labels, structured metadata, etc.
    {{- if eq .Values.logFormat "json" }}
    stage.json {
      expressions = {
        "component" = "sourcecomponent", // map the sourcecomponent field to component
        "kind" = "",
        "level" = "type", // most events don't have a level but they do have a "type" i.e. Normal, Warning, Error, etc.
        "name" = "",
        "node" = "sourcehost", // map the sourcehost field to node
      }
    }
    {{- else }}
    stage.logfmt {
      mapping = {
        "component" = "sourcecomponent", // map the sourcecomponent field to component
        "kind" = "",
        "level" = "type", // most events don't have a level but they do have a "type" i.e. Normal, Warning, Error, etc.
        "name" = "",
        "node" = "sourcehost", // map the sourcehost field to node
      }
    }
    {{- end }}
    // set these values as labels, they may or may not be used as index labels in Loki as they can be dropped
    // prior to being written to Loki, but this makes them available
    stage.labels {
      values = {
        "component" = "",
        "kind" = "",
        "level" = "",
        "name" = "",
        "node" = "",
      }
    }

    // if kind=Node, set the node label by copying the instance label
    stage.match {
      selector = "{kind=\"Node\"}"

      stage.labels {
        values = {
          "node" = "name",
        }
      }
    }

    // set the level extracted key value as a normalized log level
    stage.match {
      selector = "{level=\"Normal\"}"

      stage.static_labels {
        values = {
          level = "Info",
        }
      }
    }

    {{- if .Values.extraLogProcessingStages }}
    {{ tpl .Values.extraLogProcessingStages $ | indent 4 }}
    {{ end }}

    {{- /* the stage.structured_metadata block needs to be conditionalized because the support for enabling structured metadata can be disabled */ -}}
    {{- /* through the loki limits_conifg on a per-tenant basis, even if there are no values defined or there are values defined but it is disabled */ -}}
    {{- /* in Loki, the write will fail. */ -}}
    {{- if gt (len (keys .Values.structuredMetadata)) 0 }}
    // set the structured metadata values
    stage.structured_metadata {
      values = {
        {{- range $key, $value := .Values.structuredMetadata }}
        {{ $key | quote }} = {{ if $value }}{{ $value | quote }}{{ else }}{{ $key | quote }}{{ end }},
        {{- end }}
      }
    }
    {{- end }}

    // Only keep the labels that are defined in the `keepLabels` list.
    stage.label_keep {
      values = {{ .Values.labelsToKeep | toJson }}
    }
    forward_to = argument.logs_destinations.value
  }
}
{{- end -}}

{{- define "feature.clusterEvents.alloyModules" }}{{- end }}
