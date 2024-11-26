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
    rule {
      action = "replace"
      source_labels = ["__journal__systemd_unit"]
      replacement = "$1"
      target_label = "unit"
    }
  {{- if .Values.journal.extraDiscoveryRules }}
  {{ .Values.journal.extraDiscoveryRules | indent 2 }}
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
      instance = env("HOSTNAME"),
    }
    forward_to = [loki.process.journal_logs.receiver]
  }

  loki.process "journal_logs" {
  {{- if .Values.journal.extraLogProcessingBlocks }}
  {{ tpl .Values.journal.extraLogProcessingBlocks . | indent 2 }}
  {{ end }}
    forward_to = argument.logs_destinations.value
  }
}
{{- end -}}

{{- define "feature.nodeLogs.alloyModules" }}{{- end }}
