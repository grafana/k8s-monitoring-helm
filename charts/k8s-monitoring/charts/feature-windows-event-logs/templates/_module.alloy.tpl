{{- /* Renders a single loki.source.windowsevent component for an event log source. */ -}}
{{- /* Inputs: source (a single entry from .Values.sources), Values (feature values) */ -}}
{{- define "feature.windowsEventLogs.source" }}
{{- $source := .source }}
{{- $xpathQuery := $source.xpathQuery | default "*" }}
loki.source.windowsevent {{ $source.name | quote }} {
  {{- if $source.eventLogName }}
  eventlog_name          = {{ $source.eventLogName | quote }}
  {{- end }}
  {{- if ne $xpathQuery "*" }}
  xpath_query            = {{ $xpathQuery | quote }}
  {{- end }}
  poll_interval          = {{ .Values.pollInterval | quote }}
  use_incoming_timestamp = {{ .Values.useIncomingTimestamp }}
  exclude_event_data     = {{ .Values.excludeEventData }}
  exclude_user_data      = {{ .Values.excludeUserData }}
  exclude_event_message  = {{ .Values.excludeEventMessage }}
  locale                 = {{ .Values.locale }}
  {{- if .Values.bookmarks.enabled }}
  bookmark_path          = {{ printf "%s\\%s.xml" .Values.bookmarks.hostPath $source.name | quote }}
  {{- end }}
  labels = {
    {{- if $source.jobLabel }}
    job = {{ $source.jobLabel | quote }},
    {{- end }}
    instance = sys.env("HOSTNAME"),
    {{- if $source.eventLogName }}
    channel = {{ $source.eventLogName | quote }},
    {{- end }}
    {{- range $key, $value := $source.labels }}
    {{ $key }} = {{ $value | quote }},
    {{- end }}
  }
  forward_to = [loki.process.windows_event_logs.receiver]
} // loki.source.windowsevent {{ $source.name | quote }}
{{- end -}}

{{- define "feature.windowsEventLogs.module" }}
declare "windows_event_logs" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  {{- range $source := .Values.sources }}
  {{- include "feature.windowsEventLogs.source" (dict "source" $source "Values" $.Values) | indent 2 }}
  {{- end }}

  loki.process "windows_event_logs" {
    stage.static_labels {
      values = {
        // add a static source label to the logs so they can be differentiated / restricted if necessary
        "source" = "windowsevent",
        // default level to unknown
        level = "UNKNOWN",
      }
    }

    // loki.source.windowsevent emits each event as a JSON document. Extract the fields needed for processing.
    stage.json {
      expressions = {
        level_text = "levelText",
      }
    }

    // Standardize the Windows event level onto the shared level values.
    stage.match {
      selector = "{level=\"UNKNOWN\"}"

      stage.replace {
        source = "level_text"
        expression = "(?i)^(verbose)$"
        replace = "DEBUG"
      }

      stage.replace {
        source = "level_text"
        expression = "(?i)^(information|info)$"
        replace = "INFO"
      }

      stage.replace {
        source = "level_text"
        expression = "(?i)^(warning|warn)$"
        replace = "WARN"
      }

      stage.replace {
        source = "level_text"
        expression = "(?i)^(error|err)$"
        replace = "ERROR"
      }

      stage.replace {
        source = "level_text"
        expression = "(?i)^(critical|crit)$"
        replace = "CRIT"
      }

      stage.labels {
        values = {
          level = "level_text",
        }
      }
    }

  {{- /* Extract event fields needed for extraLabels */}}
  {{- range $label, $field := .Values.extraLabels }}
    stage.json {
      expressions = {
        {{ include "escape_label" $label }} = {{ $field | quote }},
      }
    }
    stage.labels {
      values = {
        {{ $label | quote }} = {{ include "escape_label" $label | quote }},
      }
    }
  {{- end }}

    {{- /* the stage.structured_metadata block needs to be conditionalized because the support for enabling structured metadata can be disabled */ -}}
    {{- /* through the loki limits_config on a per-tenant basis, even if there are no values defined or there are values defined but it is disabled */ -}}
    {{- /* in Loki, the write will fail. */ -}}
    {{- if gt (len (keys .Values.structuredMetadata)) 0 }}
    // extract the fields used for structured metadata
    stage.json {
      expressions = {
        {{- range $key, $field := .Values.structuredMetadata }}
        {{ include "escape_label" $key }} = {{ $field | quote }},
        {{- end }}
      }
    }

    // set the structured metadata values
    stage.structured_metadata {
      values = {
        {{- range $key, $field := .Values.structuredMetadata }}
        {{ $key | quote }} = {{ include "escape_label" $key | quote }},
        {{- end }}
      }
    }
    {{- end }}

    {{- if .Values.extraLogProcessingStages }}
    {{ tpl .Values.extraLogProcessingStages . | indent 4 }}
    {{ end }}

    forward_to = argument.logs_destinations.value
  } // loki.process "windows_event_logs"
} // declare "windows_event_logs"
{{- end -}}
