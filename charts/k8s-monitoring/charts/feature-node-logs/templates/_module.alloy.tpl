{{- define "feature.nodeLogs.module" }}
declare "node_logs" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  loki.relabel "journal" {
    {{- if len .Values.journal.units }}
    rule {
      action = "keep"
      source_labels = ["__journal__systemd_unit"]
      regex = "{{ join "|" .Values.journal.units }}"
    }
    {{- end }}

    // copy all journal labels and make the available to the pipeline stages as labels, there is a label
    // keep defined to filter out unwanted labels, these pipeline labels can be set as structured metadata
    // as well, the following labels are available:
    // - boot_id
    // - cap_effective
    // - cmdline
    // - comm
    // - exe
    // - gid
    // - hostname
    // - machine_id
    // - pid
    // - stream_id
    // - systemd_cgroup
    // - systemd_invocation_id
    // - systemd_slice
    // - systemd_unit
    // - transport
    // - uid
    //
    // More Info: https://www.freedesktop.org/software/systemd/man/systemd.journal-fields.html
    rule {
      action = "labelmap"
      regex = "__journal__(.+)"
    }

    rule {
      action = "replace"
      source_labels = ["__journal__systemd_unit"]
      replacement = "$1"
      target_label = "unit"
    }

    // the service_name label will be set automatically in loki if not set, and the unit label
    // will not allow service_name to be set automatically.
    rule {
      action = "replace"
      source_labels = ["__journal__systemd_unit"]
      replacement = "$1"
      target_label = "service_name"
    }
  {{- if .Values.extraDiscoveryRules }}
  {{ .Values.extraDiscoveryRules | indent 2 }}
  {{- end }}

    forward_to = [] // No forward_to is used in this component, the defined rules are used in the loki.source.journal component
  }

  loki.source.journal "worker" {
    path = {{ .Values.journal.path | quote }}
    format_as_json = {{ .Values.journal.formatAsJson }}
    max_age = {{ .Values.journal.maxAge | quote }}
    relabel_rules = loki.relabel.journal.rules
    labels = {
      job = {{ .Values.journal.jobLabel | quote }},
      instance = sys.env("HOSTNAME"),
    }
    forward_to = [loki.process.journal_logs.receiver]
  }

  loki.process "journal_logs" {
    stage.static_labels {
      values = {
        // add a static source label to the logs so they can be differentiated / restricted if necessary
        "source" = "journal",
        // default level to unknown
        level = "unknown",
      }
    }

    // Attempt to determine the log level, most k8s workers are either in logfmt or klog formats
    // check to see if the log line matches the klog format (https://github.com/kubernetes/klog)
    stage.match {
      // unescaped regex: ([IWED][0-9]{4}\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+)
      selector = "{level=\"unknown\"} |~ \"([IWED][0-9]{4}\\\\s+[0-9]{2}:[0-9]{2}:[0-9]{2}\\\\.[0-9]+)\""

      // extract log level, klog uses a single letter code for the level followed by the month and day i.e. I0119
      stage.regex {
        expression = "((?P<level>[A-Z])[0-9])"
      }

      // if the extracted level is I set INFO
      stage.replace {
        source = "level"
        expression = "(I)"
        replace = "INFO"
      }

      // if the extracted level is W set WARN
      stage.replace {
        source = "level"
        expression = "(W)"
        replace = "WARN"
      }

      // if the extracted level is E set ERROR
      stage.replace {
        source = "level"
        expression = "(E)"
        replace = "ERROR"
      }

      // if the extracted level is I set INFO
      stage.replace {
        source = "level"
        expression = "(D)"
        replace = "DEBUG"
      }

      // set the extracted level to be a label
      stage.labels {
        values = {
          level = "",
        }
      }
    }

    // if the level is still unknown, do one last attempt at detecting it based on common levels
    stage.match {
      selector = "{level=\"unknown\"}"

      // unescaped regex: (?i)(?:"(?:level|loglevel|levelname|lvl|levelText|SeverityText)":\s*"|\s*(?:level|loglevel|levelText|lvl)="?|\s+\[?)(?P<level>(DEBUG?|DBG|INFO?(RMATION)?|WA?RN(ING)?|ERR(OR)?|CRI?T(ICAL)?|FATAL|FTL|NOTICE|TRACE|TRC|PANIC|PNC|ALERT|EMERGENCY))("|\s+|-|\s*\])
      stage.regex {
        expression = "(?i)(?:\"(?:level|loglevel|levelname|lvl|levelText|SeverityText)\":\\s*\"|\\s*(?:level|loglevel|levelText|lvl)=\"?|\\s+\\[?)(?P<level>(DEBUG?|DBG|INFO?(RMATION)?|WA?RN(ING)?|ERR(OR)?|CRI?T(ICAL)?|FATAL|FTL|NOTICE|TRACE|TRC|PANIC|PNC|ALERT|EMERGENCY))(\"|\\s+|-|\\s*\\])"
      }

      // set the extracted level to be a label
      stage.labels {
        values = {
          level = "",
        }
      }
    }

    {{- if .Values.extraLogProcessingStages }}
    {{ tpl .Values.extraLogProcessingStages . | indent 4 }}
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

{{- define "feature.nodeLogs.alloyModules" }}{{- end }}
