{{- define "feature.kubernetesManifests.module" }}
{{- $labelSelectors := list }}
{{- range $k, $v := .Values.labelSelectors }}
  {{- if kindIs "slice" $v }}
    {{- $labelSelectors = append $labelSelectors (printf "%s in (%s)" $k (join "," $v)) }}
  {{- else }}
    {{- $labelSelectors = append $labelSelectors (printf "%s=%s" $k $v) }}
  {{- end }}
{{- end }}
declare "kubernetes_manifests" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  discovery.kubernetes "manifest_tail_pods" {
    role = "pod"
{{- if $labelSelectors }}
    selectors {
      role = "pod"
      label = {{ $labelSelectors | join "," | quote }}
    }
{{- end }}
  }

  discovery.relabel "manifest_tail_pods" {
    targets = discovery.kubernetes.manifest_tail_pods.targets

    rule {
      source_labels = ["__meta_kubernetes_pod_phase"]
      regex         = "Succeeded|Failed|Completed"
      action        = "drop"
    }

    rule {
      source_labels = ["__meta_kubernetes_namespace"]
      target_label  = "namespace"
    }

    rule {
      source_labels = ["__meta_kubernetes_pod_name"]
      target_label  = "pod"
    }

    rule {
      source_labels = ["__meta_kubernetes_pod_container_name"]
      target_label  = "container"
    }

    rule {
      replacement  = {{ .Values.jobLabel | quote }}
      target_label = "job"
    }
  }

  loki.source.kubernetes "manifest_tail_logs" {
    targets    = discovery.relabel.manifest_tail_pods.output
    forward_to = [loki.process.manifest_tail_logs.receiver]
  }

  loki.process "manifest_tail_logs" {
    {{- if .Values.structuredMetadata }}
    stage.structured_metadata {
      values = {
        {{- range $key, $value := .Values.structuredMetadata }}
        {{ $key | quote }} = {{ if $value }}{{ $value | quote }}{{ else }}{{ $key | quote }}{{ end }},
        {{- end }}
      }
    }
    {{- end }}

    {{- if .Values.extraLogProcessingStages }}
    {{ tpl .Values.extraLogProcessingStages $ | indent 4 }}
    {{ end }}

    forward_to = argument.logs_destinations.value
  }
}
{{- end -}}
