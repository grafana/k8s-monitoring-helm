{{- define "feature.clusterEvents.module" }}
declare "cluster_events" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  loki.source.kubernetes_events "cluster_events" {
    job_name   = {{ .Values.jobLabel | quote }}
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
        "reason" = "",
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
        "reason" = "",
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
        "reason" = "",
      }
    }

    // if kind=Node, set the node label by copying the name field
    stage.match {
      selector = "{kind=\"Node\"}"

      stage.labels {
        values = {
          "node" = "name",
        }
      }
    }

{{- if .Values.includeReasons }}
    stage.static_labels {
      values = {
        drop = "yes",
      }
    }
    stage.match {
      selector = "{reason=~\"{{ .Values.includeReasons | join "|" }}\"}"
      stage.static_labels {
        values = {
          drop = "no",
        }
      }
    }
    stage.match {
      selector = "{drop=\"yes\"}"
      action = "drop"
      drop_counter_reason = "not_included_reasons"
    }
    stage.label_drop {
      values = ["drop"]
    }
{{- end }}
{{- if .Values.excludeReasons }}
    stage.drop {
      source = "reason"
      expression = {{ .Values.excludeReasons | join "|" | quote }}
      drop_counter_reason = "excluded_reasons"
    }
{{- end }}
{{- if .Values.includeLevels }}
    stage.static_labels {
      values = {
        drop = "yes",
      }
    }
    stage.match {
      selector = "{level=~\"{{ .Values.includeLevels | join "|" }}\"}"
      stage.static_labels {
        values = {
          drop = "no",
        }
      }
    }
    stage.match {
      selector = "{drop=\"yes\"}"
      action = "drop"
      drop_counter_reason = "not_included_levels"
    }
    stage.label_drop {
      values = ["drop"]
    }
{{- end }}
{{- if .Values.excludeLevels }}
    stage.drop {
      source = "level"
      expression = {{ .Values.excludeLevels | join "|" | quote }}
      drop_counter_reason = "excluded_levels"
    }
{{- end }}

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
    stage.labels {
      values = {
        "service_name" = "job",
      }
    }
    forward_to = argument.logs_destinations.value
  }
}
{{- end -}}

{{- define "feature.clusterEvents.alloyModules" }}{{- end }}
