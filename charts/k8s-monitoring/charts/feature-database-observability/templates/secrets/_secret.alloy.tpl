{{/* This builds the remote.kubernetes.secret component for this destination */}}
{{/* Inputs: $ (top level object) object (user of the secret, needs name, secret, auth) */}}
{{ define "secret.alloy" }}
remote.kubernetes.secret {{ include "helper.alloy_name" .object.name | quote }} {
  name      = {{ include "secrets.kubernetesSecretName" . | quote }}
  namespace = {{ include "secrets.kubernetesSecretNamespace" . | quote }}
}
{{ end }}
