{{/* Inputs: Values (values) metricsOutput, logsOutput, tracesOutput, name */}}
{{/* https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.processor.resourcedetection/ */}}
{{- define "feature.applicationObservability.processor.resourcedetection.alloy.target" }}otelcol.processor.resourcedetection.{{ .name | default "default" }}.input{{ end }}
{{- define "feature.applicationObservability.processor.resourcedetection.alloy" }}
{{- $detectors := include "feature.applicationObservability.processor.resourcedetection.detectors" . | fromYamlArray }}
otelcol.processor.resourcedetection "{{ .name | default "default" }}" {
  detectors = {{ $detectors | sortAlpha | toJson }}

{{- range $detector := $detectors }}
  {{- /* Skip env, it has no settings */}}
  {{- if ne $detector "env" }}
  {{ $detectorValues := index $.Values.processors.resourceDetection $detector }}

  {{- /* Fix the case style for kubernetesNode --> kubernetes_node */}}
  {{- if eq $detector "kubernetesNode" }}
  kubernetes_node {
  {{- else }}
  {{ $detector }} {
  {{- end }}

  {{- /* Handle detectors with special arguments */}}
  {{- if eq $detector "ec2" }}
    {{- if $detectorValues.tags }}
    tags = {{ $detectorValues.tags | toJson }}
    {{- end }}
  {{- end }}
  {{- if eq $detector "consul" }}
    {{ if $detectorValues.address }}address = {{ $detectorValues.address | quote }}{{ end }}
    {{ if $detectorValues.datacenter }}datacenter = {{ $detectorValues.datacenter | quote }}{{ end }}
    {{ if $detectorValues.token }}token = {{ $detectorValues.token | quote }}{{ end }}
    {{ if $detectorValues.namespace }}namespace = {{ $detectorValues.namespace | quote }}{{ end }}
    {{ if $detectorValues.meta }}meta = {{ $detectorValues.meta | toJson }}{{ end }}
  {{- end }}
  {{- if eq $detector "system" }}
    {{- if $detectorValues.hostnameSources }}
    hostname_sources = {{ $detectorValues.hostnameSources | toJson }}
    {{- end }}
  {{- end }}
  {{- if eq $detector "openshift" }}
    {{ if $detectorValues.address }}address = {{ $detectorValues.address | quote }}{{ end }}
    {{ if $detectorValues.token }}token = {{ $detectorValues.token | quote }}{{ end }}
  {{- end }}
  {{- if eq $detector "kubernetesNode" }}
    {{ if $detectorValues.authType }}auth_type = {{ $detectorValues.authType | quote }}{{ end }}
    {{ if $detectorValues.nodeFromEnvVar }}node_from_env_var = {{ $detectorValues.nodeFromEnvVar | quote }}{{ end }}
  {{- end }}

  {{- if $detectorValues.resourceAttributes }}
    resource_attributes {
    {{- range $key, $value := $detectorValues.resourceAttributes }}
      {{ if $value.enabled }}{{ $key }} { enabled = true }{{ end }}
    {{- end }}
    }
  {{- end }}
  }
  {{- end }}
{{- end }}

  output {
{{- if and .metrics .Values.metrics.enabled }}
    metrics = {{ .metrics }}
{{- end }}
{{- if and .logs .Values.logs.enabled }}
    logs = {{ .logs }}
{{- end }}
{{- if and .traces .Values.traces.enabled }}
    traces = {{ .traces }}
{{- end }}
  }
}
{{- end }}

{{- define "feature.applicationObservability.processor.resourcedetection.detectors" }}
{{- $enabledDetectors := list }}
{{- range $detector, $options := .Values.processors.resourceDetection }}
  {{- if $options.enabled }}
    {{- $enabledDetectors = append $enabledDetectors $detector }}
  {{- end }}
{{- end }}
{{ $enabledDetectors | toJson }}
{{- end }}

{{- define "feature.applicationObservability.processor.resourcedetection.enabled" }}
{{- $detectors := include "feature.applicationObservability.processor.resourcedetection.detectors" . | fromYamlArray }}
{{- gt (len $detectors) 0 }}
{{- end }}
