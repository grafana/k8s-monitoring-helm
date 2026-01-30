{{- define "feature.podLogsViaKubernetesApi.processing.alloy" }}
{{- $criSelector := "{tmp_container_runtime=~\"containerd|cri-o\"}" }}
{{- $dockerSelector := "{tmp_container_runtime=\"docker\"}" }}
{{- if eq .Values.defaultLogFormat "cri" }}
  {{- $criSelector = "{tmp_container_runtime=~\"containerd|cri-o|\"}" }}
{{- else if eq .Values.defaultLogFormat "docker" }}
  {{- $dockerSelector = "{tmp_container_runtime=~\"docker|\"}" }}
{{- end }}
loki.process "pod_logs" {
  stage.match {
    selector = {{ $criSelector | quote }}
    // the cri processing stage extracts the following k/v pairs: log, stream, time, flags
    stage.cri {
{{- if .Values.cri.maxPartialLines }}
      max_partial_lines = {{ .Values.cri.maxPartialLines }}
{{- end }}
    }

    // Set the extract flags and stream values as labels
    stage.labels {
      values = {
        flags  = "",
        stream  = "",
      }
    }
  }

  stage.match {
    selector = {{ $dockerSelector | quote }}
    // the docker processing stage extracts the following k/v pairs: log, stream, time
    stage.docker {}

    // Set the extract stream value as a label
    stage.labels {
      values = {
        stream  = "",
      }
    }
  }

  // The default processing stage if tmp_container_runtime is not set or empty.
  stage.match {
    selector = "{tmp_container_runtime=""}"
    // the docker processing stage extracts the following k/v pairs: log, stream, time
    stage.cri {
{{- if .Values.cri.maxPartialLines }}
      max_partial_lines = {{ .Values.cri.maxPartialLines }}
{{- end }}
    }

    // Set the extract flags and stream values as labels
    stage.labels {
      values = {
        flags  = "",
        stream  = "",
      }
    }
  }

  // Drop the filename label, since it's not really useful in the context of Kubernetes, where we already have cluster,
  // namespace, pod, and container labels. Drop any structured metadata. Also drop the temporary
  // container runtime label as it is no longer needed.
  stage.label_drop {
    values = [
      "filename",
      "tmp_container_runtime",
    ]
  }

{{- /* the stage.structured_metadata block needs to be conditionalized because the support for enabling structured metadata can be disabled */ -}}
{{- /* through the loki limits_conifg on a per-tenant basis, even if there are no values defined or there are values defined but it is disabled */ -}}
{{- /* in Loki, the write will fail. */ -}}
{{- if .Values.structuredMetadata }}
  stage.structured_metadata {
    values = {
    {{- range $key, $value := .Values.structuredMetadata }}
      {{- if $value }}
      {{ (include "escape_label" $key) | quote }} = {{ (include "escape_label" $value) | quote }},
      {{- end }}
    {{- end }}
    }
  }
{{- end }}

{{- if or .Values.staticLabels .Values.staticLabelsFrom }}

  stage.static_labels {
    values = {
    {{- range $key, $value := .Values.staticLabels }}
      {{ $key }} = {{ $value | quote }},
    {{- end }}
    {{- range $key, $value := .Values.staticLabelsFrom }}
      {{ $key }} = {{ $value }},
    {{- end }}
    }
  }
{{- end }}
{{- if .Values.extraLogProcessingStages }}
{{ tpl .Values.extraLogProcessingStages $ | indent 2 }}
{{- end }}

{{- if .Values.labelsToKeep }}
  {{- $alwaysKeepLabels := list "__tenant_id__" }}
  {{- $lokiLabels := $alwaysKeepLabels }}
  {{- range $label := .Values.labelsToKeep }}
    {{- $lokiLabels = append $lokiLabels (include "escape_label" $label) }}
  {{- end }}

  // Only keep the labels that are defined in the `keepLabels` list.
  stage.label_keep {
    values = {{ $lokiLabels | toJson }}
  }
{{- end }}
{{ if .Values.secretFilter.enabled }}
{{- if .Values.secretFilter.inclusionSelector }}
  forward_to = [loki.process.secret_filter_prefilter.receiver]
}

loki.process "secret_filter_prefilter" {
  stage.static_labels {
    values = {
      k8s_monitoring_secret_filter_inclusion = "false",
    }
  }
  stage.match {
    selector = {{ .Values.secretFilter.inclusionSelector | quote }}

    stage.static_labels {
      values = {
        k8s_monitoring_secret_filter_inclusion = "true",
      }
    }
  }
  forward_to = [
    loki.process.secret_filter_inclusion.receiver,
    loki.process.secret_filter_exclusion.receiver,
  ]
}

loki.process "secret_filter_exclusion" {
  stage.match {
    selector = "{k8s_monitoring_secret_filter_inclusion=\"true\"}"
    action = "drop"
  }

  forward_to = argument.logs_destinations.value
}

loki.process "secret_filter_inclusion" {
  stage.match {
    selector = "{k8s_monitoring_secret_filter_inclusion=\"false\"}"
    action = "drop"
  }

{{- end }}
  forward_to = [loki.secretfilter.pod_logs.receiver]
}

loki.secretfilter "pod_logs" {
{{- if .Values.secretFilter.gitleaksConfigPathFrom }}
  gitleaks_config = {{ .Values.secretFilter.gitleaksConfigPathFrom }}
{{- else if .Values.secretFilter.gitleaksConfigPath }}
  gitleaks_config = {{ .Values.secretFilter.gitleaksConfigPath | quote }}
{{- end }}
  enable_entropy = {{ .Values.secretFilter.enableEntropy }}
  include_generic = {{ .Values.secretFilter.includeGeneric }}
  partial_mask = {{ .Values.secretFilter.partialMask }}
{{- if .Values.secretFilter.allowlist }}
  allowlist = [
  {{- range $value := .Values.secretFilter.allowlist }}
    {{ $value | quote }},
  {{- end }}
  ]
{{- end }}
{{- if .Values.secretFilter.redactWith }}
  redact_with = {{ .Values.secretFilter.redactWith | quote }}
{{- end }}
{{- end }}
  forward_to = argument.logs_destinations.value
}

{{- end }}
