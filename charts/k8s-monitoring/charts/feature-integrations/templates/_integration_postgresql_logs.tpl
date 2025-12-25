{{/* Inputs: . (Values) */}}
{{- define "integrations.postgresql.type.logOutput" }}
{{- $defaultValues := "integrations/postgresql-values.yaml" | .Files.Get | fromYaml }}
{{- $logOutput := false }}
{{- range $instance := .Values.postgresql.instances }}
  {{- $logOutput = or $logOutput (dig "databaseObservability" "enabled" false $instance) }}
{{- end }}
{{- $logOutput -}}
{{- end }}

{{/* Inputs: . (Values) */}}
{{- define "integrations.postgresql.type.logRules" }}
{{- $defaultValues := "integrations/postgresql-values.yaml" | .Files.Get | fromYaml }}
{{- $logsEnabled := false }}
{{- range $instance := .Values.postgresql.instances }}
  {{- $logsEnabled = or $logsEnabled (dig "logs" "enabled" true $instance) }}
{{- end }}
{{- $logsEnabled -}}
{{- end }}

{{- define "integrations.postgresql.logs.discoveryRules" }}
  {{- range $instance := $.Values.postgresql.instances }}
    {{- if ne (dig "logs" "enabled" true $instance) false }}
      {{- $labelList := list }}
      {{- $valueList := list }}
      {{- if .logs.namespaces }}
        {{- $labelList = append $labelList "__meta_kubernetes_namespace" -}}
        {{- $valueList = append $valueList (printf "(?:%s)" (join "|" .logs.namespaces)) -}}
      {{- end }}
      {{- range $k, $v := .logs.labelSelectors }}
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
  replacement = "postgresql"
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

{{- define "integrations.postgresql.logs.processingStage" }}
  {{- if eq (include "integrations.postgresql.type.logRules" .) "true" }}
// Integration: postgresql
stage.match {
  selector = "{integration=\"postgresql\"}"

  stage.static_labels {
    values = {
      job = "integrations/postgresql",
    }
  }

  stage.label_drop {
    values = ["integration"]
  }
}
  {{- end }}
{{- end }}
