{{/* Inputs: . (Values) */}}
{{- define "integrations.grafana.type.logs" }}
{{- $defaultValues := "integrations/grafana-values.yaml" | .Files.Get | fromYaml }}
{{- $logsEnabled := false }}
{{- range $instance := .Values.grafana.instances }}
  {{- with merge (deepCopy $defaultValues) (deepCopy $instance) (dict "type" "integration.grafana") }}
    {{- $logsEnabled = or $logsEnabled .logs.enabled }}
  {{- end }}
{{- end }}
{{- $logsEnabled -}}
{{- end }}

{{- define "integrations.grafana.logs.discoveryRules" }}
  {{- $defaultValues := "integrations/grafana-values.yaml" | .Files.Get | fromYaml }}
  {{- range $instance := $.Values.grafana.instances }}
    {{- with $defaultValues | merge (deepCopy $instance) }}
      {{- if .logs.enabled }}
        {{- $labelList := list }}
        {{- $valueList := list }}
        {{- if .namespaces }}
          {{- $labelList = append $labelList "__meta_kubernetes_namespace" -}}
          {{- $valueList = append $valueList (printf "(?:%s)" (join "|" .namespaces)) -}}
        {{- end }}
        {{- range $k, $v := .labelSelectors }}
          {{- if kindIs "slice" $v }}
            {{- $labelList = append $labelList (include "pod_label" $k) -}}
            {{- $valueList = append $valueList (printf "(?:%s)" (join "|" $v)) -}}
          {{- else }}
            {{- $labelList = append $labelList (include "pod_label" $k) -}}
            {{- $valueList = append $valueList (printf "(?:%s)" $v) -}}
          {{- end }}
        {{- end }}
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "job"
  replacement = "integrations/grafana"
}
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "instance"
  replacement = {{ $instance.name | quote }}
}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "integrations.grafana.logs.processingStage" }}
  {{- if eq (include "integrations.grafana.type.logs" .) "true" }}
    {{- $defaultValues := "integrations/grafana-values.yaml" | .Files.Get | fromYaml }}
// Integration: Grafana
    {{- range $instance := $.Values.grafana.instances }}
      {{- with $defaultValues | merge (deepCopy $instance) }}
        {{- if .logs.enabled }}
stage.match {
  {{- if $instance.namespaces }}
  selector = "{job=\"integrations/grafana\",instance=\"{{ $instance.name }}\",namespace=~\"{{ $instance.namespaces | join "|" }}\"}"
  {{- else }}
  selector = "{job=\"integrations/grafana\",instance=\"{{ $instance.name }}\"}"
  {{- end }}

  // extract some of the fields from the log line
  stage.logfmt {
    mapping = {
      "ts" = "t",
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
    expression = `(?:^|\s+)(t=\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+[^ ]*\s+)`
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
  {{- /* through the grafana limits_conifg on a per-tenant basis, even if there are no values defined or there are values defined but it is disabled */ -}}
  {{- /* in Grafana, the write will fail. */ -}}
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
    drop_counter_reason = "grafana-drop-log-level"
  }
  {{- end }}

  {{- if and .logs.tuning.excludeLines (gt (len .logs.tuning.excludeLines) 0) }}
  // drop certain log lines
  stage.drop {
    source = ""
    expression = "(?i)({{ .logs.tuning.excludeLines | join "|" }})"
    drop_counter_reason = "grafana-exclude-line"
  }
  {{- end }}

}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
