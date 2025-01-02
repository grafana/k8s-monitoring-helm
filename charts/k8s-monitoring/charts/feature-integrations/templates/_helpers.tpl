{{/*
Create a default fully qualified name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "integrations.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" | lower }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride | lower }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" | lower }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" | lower }}
{{- end }}
{{- end }}
{{- end }}

{{ define "helper.alloy_name" }}
{{- . | lower | replace "-" "_" -}}
{{ end }}

{{- define "escape_label" -}}
{{ . | replace "-" "_" | replace "." "_" | replace "/" "_" }}
{{- end }}

{{- define "pod_label" -}}
{{ printf "__meta_kubernetes_pod_label_%s" (include "escape_label" .) }}
{{- end }}

{{- define "english_list" }}
{{- if eq (len .) 0 }}
{{- else if eq (len .) 1 }}
{{- index . 0 }}
{{- else if eq (len .) 2 }}
{{- index . 0 }} and {{ index . 1 }}
{{- else }}
{{- $last := index . (sub (len .) 1) }}
{{- $rest := slice . 0 (sub (len .) 1) }}
{{- join ", " $rest }}, and {{ $last }}
{{- end }}
{{- end }}

{{- define "commonRelabelings" }}
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

// set the workload to the controller kind and name
rule {
  action = "lowercase"
  source_labels = ["__meta_kubernetes_pod_controller_kind"]
  target_label  = "workload_type"
}

rule {
  source_labels = ["__meta_kubernetes_pod_controller_name"]
  target_label  = "workload"
}

// remove the hash from the ReplicaSet
rule {
  source_labels = [
    "workload_type",
    "workload",
  ]
  separator = "/"
  regex = "replicaset/(.+)-.+$"
  target_label  = "workload"
}

// set the app name if specified as metadata labels "app:" or "app.kubernetes.io/name:" or "k8s-app:"
rule {
  action = "replace"
  source_labels = [
    "__meta_kubernetes_pod_label_app_kubernetes_io_name",
    "__meta_kubernetes_pod_label_k8s_app",
    "__meta_kubernetes_pod_label_app",
  ]
  separator = ";"
  regex = "^(?:;*)?([^;]+).*$"
  replacement = "$1"
  target_label = "app"
}

// set the component if specified as metadata labels "component:" or "app.kubernetes.io/component:" or "k8s-component:"
rule {
  action = "replace"
  source_labels = [
    "__meta_kubernetes_pod_label_app_kubernetes_io_component",
    "__meta_kubernetes_pod_label_k8s_component",
    "__meta_kubernetes_pod_label_component",
  ]
  regex = "^(?:;*)?([^;]+).*$"
  replacement = "$1"
  target_label = "component"
}

// set a source label
rule {
  action = "replace"
  replacement = "kubernetes"
  target_label = "source"
}
{{- end }}
