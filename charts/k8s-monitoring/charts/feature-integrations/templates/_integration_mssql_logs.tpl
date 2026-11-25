{{/* Inputs: . (Values) */}}
{{- define "integrations.mssql.type.logOutput" }}
{{- $defaultValues := "integrations/mssql-values.yaml" | .Files.Get | fromYaml }}
{{- $logOutput := false }}
{{- range $instance := .Values.mssql.instances }}
  {{- $logOutput = or $logOutput (dig "databaseObservability" "enabled" false $instance) }}
{{- end }}
{{- $logOutput -}}
{{- end }}

{{/* Inputs: . (Values) */}}
{{- define "integrations.mssql.type.logRules" }}
{{- $defaultValues := "integrations/mssql-values.yaml" | .Files.Get | fromYaml }}
{{- $logsEnabled := false }}
{{- range $instance := .Values.mssql.instances }}
  {{- $logsEnabled = or $logsEnabled (dig "logs" "enabled" true $instance) }}
{{- end }}
{{- $logsEnabled -}}
{{- end }}

{{- define "integrations.mssql.logs.discoveryRules" }}
  {{- $defaultValues := "integrations/mssql-values.yaml" | .Files.Get | fromYaml }}
  {{- range $instance := $.Values.mssql.instances }}
    {{- if ne (dig "logs" "enabled" true $instance) false }}
      {{- $merged := mergeOverwrite (deepCopy $defaultValues) $instance }}
      {{- $labelList := list }}
      {{- $valueList := list }}
      {{- if $merged.logs.namespaces }}
        {{- $labelList = append $labelList "__meta_kubernetes_namespace" -}}
        {{- $valueList = append $valueList (printf "(?:%s)" (join "|" $merged.logs.namespaces)) -}}
      {{- end }}
      {{- range $k, $v := $merged.logs.labelSelectors }}
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
  target_label = "integration"
  replacement = "mssql"
}
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "job"
  replacement = {{ $merged.jobLabel | quote }}
}
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "instance"
  replacement = {{ $merged.name | quote }}
}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "integrations.mssql.logs.processingStage" }}
  {{- if eq (include "integrations.mssql.type.logRules" .) "true" }}
// Integration: MSSQL
stage.match {
  selector = "{integration=\"mssql\"}"

  stage.label_drop {
    values = ["integration"]
  }
}
  {{- end }}
{{- end }}
