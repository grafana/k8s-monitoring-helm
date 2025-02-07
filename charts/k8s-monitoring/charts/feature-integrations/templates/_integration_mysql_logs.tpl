{{/* Inputs: . (Values) */}}
{{- define "integrations.mysql.type.logs" }}
{{- $defaultValues := "integrations/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- $logsEnabled := false }}
{{- range $instance := .Values.mysql.instances }}
  {{- $logsEnabled = or $logsEnabled (dig "logs" "enabled" true $instance) }}
{{- end }}
{{- $logsEnabled -}}
{{- end }}

{{- define "integrations.mysql.logs.discoveryRules" }}
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
rule {
  source_labels = {{ $labelList | toJson }}
  separator = ";"
  regex = {{ $valueList | join ";" | quote }}
  target_label = "integration"
  replacement = "mysql"
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

{{- define "integrations.mysql.logs.processingStage" }}
  {{- if eq (include "integrations.mysql.type.logs" .) "true" }}
// Integration: MySQL
stage.match {
  selector = "{integration=\"mysql\"}"

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

  stage.static_labels {
    values = {
      job = "integrations/mysql",
    }
  }

  stage.label_drop {
    values = ["integration"]
  }
}
  {{- end }}
{{- end }}
