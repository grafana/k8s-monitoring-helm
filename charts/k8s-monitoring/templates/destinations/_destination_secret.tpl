{{/* This builds the remote.kubernetes.secret component for this destination */}}
{{/* Inputs: destination (destination definition) Release (Release object) Chart (Chart object) */}}
{{ define "destinations.secret.alloy" }}
remote.kubernetes.secret {{ include "helper.alloy_name" .destination.name | quote }} {
  name      = {{ include "destinations.secret.k8s_secret_name" (dict "destination" .destination "Release" .Release "Chart" .Chart) | quote }}
  namespace = {{ include "destinations.secret.k8s_secret_namespace" (dict "destination" .destination "Release" .Release) | quote }}
}
{{ end }}
