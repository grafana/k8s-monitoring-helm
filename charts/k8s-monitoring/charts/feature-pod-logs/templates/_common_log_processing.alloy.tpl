{{- define "feature.podLogs.processing.alloy" }}
loki.process "pod_logs" {
  stage.match {
    selector = "{tmp_container_runtime=~\"containerd|cri-o\"}"
    // the cri processing stage extracts the following k/v pairs: log, stream, time, flags
    stage.cri {}

    // Set the extract flags and stream values as labels
    stage.labels {
      values = {
        flags  = "",
        stream  = "",
      }
    }
  }

  stage.match {
    selector = "{tmp_container_runtime=\"docker\"}"
    // the docker processing stage extracts the following k/v pairs: log, stream, time
    stage.docker {}

    // Set the extract stream value as a label
    stage.labels {
      values = {
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
  forward_to = [loki.secretfilter.pod_logs.receiver]
}

loki.secretfilter "pod_logs" {
  include_generic = {{ .Values.secretFilter.includeGeneric }}
  partial_mask = {{ .Values.secretFilter.partialMask }}
{{- if .Values.secretFilter.allowlist }}
  allowlist = [
  {{- range $value := .Values.secretFilter.allowlist }}
    {{ $value | quote }},
  {{- end }}
  ]
{{- end }}
{{- end }}
  forward_to = argument.logs_destinations.value
}

{{- end }}
