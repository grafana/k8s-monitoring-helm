{{/* Validates that the Alloy instance is appropriate for the given Kubernetes Manifests settings */}}
{{/* Inputs: Values (Kubernetes Manifests values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.kubernetesManifests.collector.validate" -}}
{{/*{{- if and (hasPrefix "/var/kubernetes-manifests" .Values.path) (not .Collector.alloy.mounts.varlog) }}*/}}
{{/*  {{- $msg := list "" "Kubernetes Manifests feature requires Alloy to mount /var/log." }}*/}}
{{/*  {{- $msg = append $msg "Please set:"}}*/}}
{{/*  {{- $msg = append $msg (printf "%s:" .CollectorName) }}*/}}
{{/*  {{- $msg = append $msg "  alloy:"}}*/}}
{{/*  {{- $msg = append $msg "    mounts:"}}*/}}
{{/*  {{- $msg = append $msg "      varlog: true" }}*/}}
{{/*  {{- fail (join "\n" $msg) }}*/}}
{{/*{{- end -}}*/}}
{{- end -}}
