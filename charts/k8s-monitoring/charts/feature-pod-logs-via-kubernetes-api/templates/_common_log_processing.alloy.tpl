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

{{- /* service_instance_id is unique per pod instance (namespace.pod.container), so keeping it
  as an indexed label creates a brand-new Loki stream on every pod restart/rollout/Job run,
  unbounded over time -- see https://github.com/grafana/k8s-monitoring-helm/issues/3051. It is
  already captured above by the default structuredMetadata entry (queryable, not indexed), so
  drop the indexed copy once captured. Only applies when the structuredMetadata entry for it is
  present, so removing that entry also opts out of this drop. */ -}}
{{- if hasKey .Values.structuredMetadata "service.instance.id" }}
  stage.label_drop {
    values = ["service_instance_id"]
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
{{ if .Values.secretFilter.enabled }}
{{- if .Values.secretFilter.inclusionSelector }}
  forward_to = [loki.process.secret_filter_prefilter.receiver]
} // loki.process "pod_logs"

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
} // loki.process "secret_filter_prefilter"

loki.process "secret_filter_exclusion" {
  stage.match {
    selector = "{k8s_monitoring_secret_filter_inclusion=\"true\"}"
    action = "drop"
  }

  forward_to = argument.logs_destinations.value
} // loki.process "secret_filter_exclusion"

loki.process "secret_filter_inclusion" {
  stage.match {
    selector = "{k8s_monitoring_secret_filter_inclusion=\"false\"}"
    action = "drop"
  }

  forward_to = [loki.secretfilter.pod_logs.receiver]
} // loki.process "secret_filter_inclusion"
{{- else }}
  forward_to = [loki.secretfilter.pod_logs.receiver]
} // loki.process "pod_logs"
{{- end }}

loki.secretfilter "pod_logs" {
{{- if .Values.secretFilter.gitleaksConfigPathFrom }}
  gitleaks_config = {{ .Values.secretFilter.gitleaksConfigPathFrom }}
{{- else if .Values.secretFilter.gitleaksConfigPath }}
  gitleaks_config = {{ .Values.secretFilter.gitleaksConfigPath | quote }}
{{- end }}
{{- if .Values.secretFilter.allowlist }}
  allowlist = [
  {{- range $value := .Values.secretFilter.allowlist }}
    {{ $value | quote }},
  {{- end }}
  ]
{{- end }}
{{- if .Values.secretFilter.redactWith }}
  redact_with = {{ .Values.secretFilter.redactWith | quote }}
{{- else }}
  redact_percent = {{ .Values.secretFilter.redactPercent | int }}
{{- end }}
  forward_to = argument.logs_destinations.value
} // loki.secretfilter "pod_logs"
{{- else }}
  forward_to = argument.logs_destinations.value
} // loki.process "pod_logs"
{{- end }}

{{- end }}
