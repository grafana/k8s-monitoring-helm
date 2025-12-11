{{/* Inputs: . (Values) */}}
{{- define "integrations.istio.type.logOutput" }}false{{- end }}

{{/* Inputs: . (Values) */}}
{{- define "integrations.istio.type.logRules" }}
{{- $defaultValues := "integrations/istio-values.yaml" | .Files.Get | fromYaml }}
{{- $logsEnabled := false }}
{{- range $instance := .Values.istio.instances }}
  {{- $logsEnabled = or $logsEnabled (dig "logs" "enabled" true $instance) }}
{{- end }}
{{- $logsEnabled -}}
{{- end }}

{{- define "integrations.istio.logs.discoveryRules" }}
  {{- range $instance := $.Values.istio.instances }}
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
  replacement = "istio"
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

{{- define "integrations.istio.logs.processingStage" }}
  {{- if eq (include "integrations.istio.type.logRules" .) "true" }}
// Integration: Istio
stage.match {
  selector = "{integration=\"istio\"}"

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
      job = "integrations/istio",
    }
  }

  stage.label_drop {
    values = ["integration"]
  }
}
  {{- end }}
{{- end }}
