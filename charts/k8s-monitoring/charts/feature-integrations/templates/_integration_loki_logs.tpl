{{/* Inputs: . (Values) */}}
{{- define "integrations.loki.type.logs" }}
{{- $defaultValues := "integrations/loki-values.yaml" | .Files.Get | fromYaml }}
{{- $logsEnabled := false }}
{{- range $instance := .Values.loki.instances }}
  {{- with merge $instance $defaultValues (dict "type" "integration.loki") }}
    {{- $logsEnabled = or $logsEnabled $instance.logs.enabled }}
  {{- end }}
{{- end }}
{{- $logsEnabled -}}
{{- end }}

{{- define "integrations.loki.logs.discoveryRules" }}
  {{- $defaultValues := "integrations/loki-values.yaml" | .Files.Get | fromYaml }}
  {{- range $instance := $.Values.loki.instances }}
    {{- with $defaultValues | merge (deepCopy $instance) }}
      {{- if .logs.enabled }}
        {{- $labelList := list }}
        {{- $valueList := list }}
        {{- $selectors := dict (include "integrations.loki.defaultSelectorLabel" $) ($instance.name | default (include "integrations.loki.defaultSelectorValue" $)) }}
        {{- if $instance.labelSelectors }}
          {{- $selectors = $instance.labelSelectors }}
        {{- end }}

        {{- range (keys $selectors) }}
          {{- $labelList = append $labelList (include "pod_label" .) -}}
          {{- $valueList = append $valueList (index $selectors .) -}}
        {{- end }}
rule {
  source_labels = {{ $labelList | sortAlpha | toJson }}
  separator = ";"
  regex = {{ $valueList | sortAlpha | join ";" | quote }}
  target_label = "job"
  replacement = "integrations/loki"
}
rule {
  source_labels = {{ $labelList | sortAlpha | toJson }}
  separator = ";"
  regex = {{ $valueList | sortAlpha | join ";" | quote }}
  target_label = "instance"
  replacement = {{ $instance.name | quote }}
}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "integrations.loki.logs.processingStage" }}
  {{- if eq (include "integrations.loki.type.logs" .) "true" }}
    {{- $defaultValues := "integrations/loki-values.yaml" | .Files.Get | fromYaml }}
// Integration: Loki
    {{- range $instance := $.Values.loki.instances }}
      {{- with $defaultValues | merge (deepCopy $instance) }}
        {{- if .logs.enabled }}
stage.match {
  {{- if $instance.namespaces }}
  selector = "{job=\"integrations/loki\",instance=\"{{ $instance.name }}\",namespace=~\"{{ $instance.namespaces | join "|" }}\"}"
  {{- else }}
  selector = "{job=\"integrations/loki\",instance=\"{{ $instance.name }}\"}"
  {{- end }}

  // extract some of the fields from the log line
  stage.logfmt {
    mapping = {
      "ts" = "",
      "level" = "",
      {{- range $key, $value := .logs.tuning.structuredMetadata }}
      {{ $key | quote }} = {{ if $value }}{{ $value | quote }}{{ else }}{{ $key | quote }}{{ end }},
      {{- end }}
    }
  }

  // set the level as a label
  stage.labels {
    values = {
      level = "level",
    }
  }

  {{- if .logs.tuning.timestampFormat }}
  // reset the timestamp to the extracted value
  stage.timestamp {
    source = "ts"
    format = {{ .logs.tuning.timestampFormat | quote }}
  }
  {{- end }}

  {{- if .logs.tuning.scrubTimestamp }}
  // remove the timestamp from the log line
  stage.replace {
    expression = "(ts=[^ ]+\\s+)"
    replace = ""
  }
  {{- end }}

  {{- if hasKey .logs.tuning.structuredMetadata "caller" }}
  // clean up the caller to remove the line
  stage.replace {
    source = "caller"
    expression = "(:[0-9]+$)"
    replace = ""
  }
  {{- end }}

  {{- /* the stage.structured_metadata block needs to be conditionalized because the support for enabling structured metadata can be disabled */ -}}
  {{- /* through the loki limits_conifg on a per-tenant basis, even if there are no values defined or there are values defined but it is disabled */ -}}
  {{- /* in Loki, the write will fail. */ -}}
  {{- if gt (len .logs.tuning.structuredMetadata) 0 }}
  // set the structured metadata values
  stage.structured_metadata {
    values = {
      {{- range $key, $value := .logs.tuning.structuredMetadata }}
      {{ $key | quote }} = {{ if $value }}{{ $value | quote }}{{ else }}{{ $key | quote }}{{ end }},
      {{- end }}
    }
  }
  {{- end }}

  {{- if and .logs.tuning.dropLogLevels (gt (len .logs.tuning.dropLogLevels) 0) }}
  // drop certain log levels
  stage.drop {
    source = "level"
    expression = "(?i)({{ .logs.tuning.dropLogLevels | join "|" }})"
    drop_counter_reason = "loki-drop-log-level"
  }
  {{- end }}

  {{- if and .logs.tuning.excludeLines (gt (len .logs.tuning.excludeLines) 0) }}
  // drop certain log lines
  stage.drop {
    source = ""
    expression = "(?i)({{ .logs.tuning.excludeLines | join "|" }})"
    drop_counter_reason = "loki-exclude-line"
  }
  {{- end }}

}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
