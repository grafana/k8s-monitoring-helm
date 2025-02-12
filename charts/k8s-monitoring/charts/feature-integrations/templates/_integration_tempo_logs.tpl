{{/* Inputs: . (Values) */}}
{{- define "integrations.tempo.type.logs" }}
{{- $defaultValues := "integrations/tempo-values.yaml" | .Files.Get | fromYaml }}
{{- $logsEnabled := false }}
{{- range $instance := .Values.tempo.instances }}
  {{- with merge (deepCopy $defaultValues) (deepCopy $instance) (dict "type" "integration.tempo") }}
    {{- $logsEnabled = or $logsEnabled .logs.enabled }}
  {{- end }}
{{- end }}
{{- $logsEnabled -}}
{{- end }}

{{- define "integrations.tempo.logs.discoveryRules" }}
  {{- $defaultValues := "integrations/tempo-values.yaml" | .Files.Get | fromYaml }}
  {{- range $instance := $.Values.tempo.instances }}
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
// add static label of integration="tempo" and instance="name" to pods that match the selector so they can be identified in the tempo.process stages
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "integration"
  replacement = "tempo"
}
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "instance"
  replacement = {{ $instance.name | quote }}
}
{{- $labelList = append $labelList "__meta_kubernetes_namespace" -}}
{{- $valueList = append $valueList "([^;]+)" -}}
{{- $labelList = append $labelList (include "pod_label" "component") -}}
{{- $valueList = append $valueList "([^;]+)" }}
// override the job label to be namespace/component so it aligns to the tempo-mixin
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "job"
  replacement = "$1/$2"
}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "integrations.tempo.logs.processingStage" }}
  {{- if eq (include "integrations.tempo.type.logs" .) "true" }}
    {{- $defaultValues := "integrations/tempo-values.yaml" | .Files.Get | fromYaml }}
// Integration: Tempo
    {{- range $instance := $.Values.tempo.instances }}
      {{- with $defaultValues | merge (deepCopy $instance) }}
        {{- if .logs.enabled }}
stage.match {
  {{- if $instance.namespaces }}
  selector = "{integration=\"tempo\",instance=\"{{ $instance.name }}\",namespace=~\"{{ $instance.namespaces | join "|" }}\"}"
  {{- else }}
  selector = "{integration=\"tempo\",instance=\"{{ $instance.name }}\"}"
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
  {{- /* through the tempo limits_conifg on a per-tenant basis, even if there are no values defined or there are values defined but it is disabled */ -}}
  {{- /* in Tempo, the write will fail. */ -}}
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
    drop_counter_reason = "tempo-drop-log-level"
  }
  {{- end }}

  {{- if and .logs.tuning.excludeLines (gt (len .logs.tuning.excludeLines) 0) }}
  // drop certain log lines
  stage.drop {
    source = ""
    expression = "(?i)({{ .logs.tuning.excludeLines | join "|" }})"
    drop_counter_reason = "tempo-exclude-line"
  }
  {{- end }}

}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
