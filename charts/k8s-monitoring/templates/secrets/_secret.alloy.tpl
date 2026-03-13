{{/* This builds the remote.kubernetes.secret component for this destination */}}
{{/* Inputs: $ (top level object) object (user of the secret, needs name, secret, auth) */}}
{{- define "secret.alloy" }}
{{- $objectName := .object.name | default .name }}
remote.kubernetes.secret {{ include "helper.alloy_name" $objectName | quote }} {
  name      = {{ include "secrets.kubernetesSecretName" . | quote }}
  namespace = {{ include "secrets.kubernetesSecretNamespace" . | quote }}
}
{{ end }}
