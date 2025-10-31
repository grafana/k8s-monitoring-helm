{{/* Inputs: . (Values) */}}
{{- define "databaseObservability.mysql.type.logs" }}
{{- $defaultValues := "databases/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- $logsEnabled := false }}
{{- range $instance := .Values.mysql.instances }}
  {{- $logsEnabled = or $logsEnabled (dig "logs" "enabled" true $instance) }}
{{- end }}
{{- $logsEnabled -}}
{{- end }}

{{- define "databaseObservability.mysql.logs.discoveryRules" }}
  {{- range $instance := $.Values.mysql.instances }}
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
// Database Observability: MySQL
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "db-observability-integration"
  replacement = "mysql"
}
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "instance"
  replacement = {{ $instance.name | quote }}
}
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "job"
  replacement = {{ $instance.jobLabel | quote }}
}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "databaseObservability.mysql.logs.processingStage" }}
  {{- if eq (include "databaseObservability.mysql.type.logs" .) "true" }}
// Database Observability: MySQL
stage.match {
  selector = "{db-observability-integration=\"mysql\"}"

  stage.regex {
    expression = `(?P<timestamp>.+) (?P<thread>[\d]+) \[(?P<label>.+?)\]( \[(?P<err_code>.+?)\] \[(?P<subsystem>.+?)\])? (?P<msg>.+)`
  }

  stage.labels {
    values = {
      level = "label",
      err_code = "err_code",
      subsystem = "subsystem",
    }
  }

  stage.drop {
    expression = "^ *$"
    drop_counter_reason = "drop empty lines"
  }

  stage.label_drop {
    values = ["db-observability-integration"]
  }
}
  {{- end }}
{{- end }}
