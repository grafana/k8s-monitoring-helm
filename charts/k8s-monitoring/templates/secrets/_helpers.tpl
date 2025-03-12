{{/* Helper function to return the auth type, defaulting to none */}}
{{/* Inputs: . (user of the secret, needs name, secret, auth) */}}
{{- define "secrets.authType" }}
{{- if hasKey . "auth" }}{{ .auth.type | default "none" }}{{ else }}none{{ end }}
{{- end }}

{{/* Helper function to determine the secret type */}}
{{/* Inputs: . (user of the secret, needs name, secret, auth) */}}
{{- define "secrets.secretType" }}
{{- if hasKey . "secret" }}
  {{- if eq .secret.embed true -}}embedded
  {{- else if eq .secret.create false -}}external
  {{- else }}create
  {{- end }}
{{- else -}}
create
{{- end }}
{{- end }}

{{/* Determine if a ___From field has been defined for a secret value */}}
{{/* Inputs: object (user of the secret, needs name, secret, auth), key (path to secret value) */}}
{{- define "secrets.getSecretFromRef" -}}
{{- $value := .object -}}
{{- range $pathPart := (regexSplit "\\." (printf "%sFrom" .key) -1) -}} {{/* "path.to.auth.password" --> ["path", "to", "auth" "passwordFrom"] */}}
{{- if $pathPart -}}
  {{- if not (kindIs "string" $value) -}}
    {{- if hasKey $value $pathPart -}}
      {{- $value = (index $value $pathPart) -}}
    {{- else -}}
      {{- $value = "" -}}
    {{- end -}}
  {{- else -}}
    {{- $value = "" -}}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- $value -}}
{{- end -}}

{{/* Determine the key to access a secret value within a secret component */}}
{{/* Inputs: object (user of the secret, needs name, secret, auth), key (path to secret value) */}}
{{- define "secrets.getSecretKey" -}}
{{- $value := .object -}}
{{- $defaultKey := (( regexSplit "\\." .key -1) | last) -}}             {{/* "path.to.auth.password" --> "password" */}}
{{- range $pathPart := (regexSplit "\\." (printf "%sKey" .key) -1) -}}  {{/* "path.to.auth.password" --> ["path", "to", "auth" "passwordKey"] */}}
{{- if $pathPart -}}
  {{- if not (kindIs "string" $value) -}}
    {{- if hasKey $value $pathPart -}}
      {{- $value = (index $value $pathPart) -}}
    {{- else -}}
      {{- $value = $defaultKey -}}
    {{- end -}}
  {{- else -}}
    {{- $value = $defaultKey -}}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- $value -}}
{{- end -}}

{{/* Determine if a key was defined by the user */}}
{{/* Inputs: object (user of the secret, needs name, secret, auth), key (path to secret value) */}}
{{- define "secrets.isSecretKeyDefined" -}}
{{- $found := true}}
{{- $value := .object -}}
{{- range $pathPart := (regexSplit "\\." (printf "%sKey" .key) -1) -}}  {{/* "path.to.auth.password" --> ["path", "to", "auth" "passwordKey"] */}}
{{- if $pathPart -}}
  {{- if not (kindIs "string" $value) -}}
    {{- if hasKey $value $pathPart -}}
      {{- $value = (index $value $pathPart) -}}
    {{- else -}}
      {{- $found = false -}}
    {{- end -}}
  {{- else -}}
    {{- $found = false -}}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- $found -}}
{{- end -}}

{{/*Determine the path to the secret value*/}}
{{/* Inputs: object (user of the secret, needs name, secret, auth), key (path to secret value) */}}
{{- define "secrets.getSecretValue" }}
{{- $value := .object -}}
{{- range $pathPart := (regexSplit "\\." .key -1) -}}  {{/* "path.to.auth.password" --> ["path", "to", "auth" "password"] */}}
{{- if $pathPart -}}
  {{- if not (kindIs "string" $value) -}}
    {{- if hasKey $value $pathPart -}}
      {{- $value = (index $value $pathPart) -}}
    {{- else -}}
      {{- $value = "" -}}
    {{- end -}}
  {{- else -}}
    {{- $value = "" -}}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- $value -}}
{{- end }}

{{/* Build the alloy command to read a secret value */}}
{{/* Inputs: object (user of the secret, needs name, secret, auth), key (path to secret value), nonsensitive */}}
{{- define "secrets.read" }}
{{- $credRef := include "secrets.getSecretFromRef" . -}}
{{- if $credRef -}}
{{ $credRef }}
{{- else if eq (include "secrets.secretType" .object) "embedded" -}}
{{ include "secrets.getSecretValue" (dict "object" .object "key" .key) | quote }}
{{- else if eq (include "secrets.usesKubernetesSecret" .object) "true" -}}
{{- $credKey := include "secrets.getSecretKey" (dict "object" .object "key" .key) -}}
{{- if .nonsensitive -}}
convert.nonsensitive(remote.kubernetes.secret.{{ include "helper.alloy_name" .object.name }}.data[{{ $credKey | quote }}])
{{- else -}}
remote.kubernetes.secret.{{ include "helper.alloy_name" .object.name }}.data[{{ $credKey | quote }}]
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Determines if the object will reference a secret value */}}
{{/* Inputs: object (user of the secret, needs name, secret, auth), key (path to secret value), nonsensitive */}}
{{- define "secrets.usesSecret" -}}
{{- $secretType := (include "secrets.secretType" .object) }}
{{- $ref := include "secrets.getSecretFromRef" . -}}
{{- $value := include "secrets.getSecretValue" . -}}
{{- if (not (eq $ref "")) }}true
{{- else if (eq $secretType "external") }}true
{{- else if (eq $value "") }}false
{{- else -}}true{{- end -}}
{{- end -}}

{{/* Determines if the object will reference a Kubernetes secret */}}
{{/* Inputs: . (user of the secret, needs name, secret, auth) */}}
{{- define "secrets.usesKubernetesSecret" -}}
{{- $secretType := (include "secrets.secretType" .) }}
{{- if eq $secretType "embedded" -}}false
{{- else -}}
  {{- $usesK8sSecret := false }}
  {{- range $secret := include (printf "secrets.list.%s" .type) . | fromYamlArray }}
    {{- $ref := include "secrets.getSecretFromRef" (dict "object" $ "key" $secret) -}}
    {{- $keyDefined := include "secrets.isSecretKeyDefined" (dict "object" $ "key" $secret) -}}
    {{- $value := include "secrets.getSecretValue" (dict "object" $ "key" $secret) -}}
    {{- if (eq $secretType "external") }}
      {{- if eq $keyDefined "true" }}{{- $usesK8sSecret = true }}{{- end }}
    {{- else }}
      {{- if and $value (not $ref) }}{{- $usesK8sSecret = true }}{{- end }}
    {{- end }}
  {{- end }}
{{- $usesK8sSecret -}}
{{- end -}}
{{- end -}}

{{/* Determines if the object will need to create a Kubernetes secret. NOTE that this object should be before merging with default values */}}
{{/* Inputs: object (user of the secret, needs name, secret, auth) */}}
{{- define "secrets.shouldCreateKubernetesSecret" -}}
{{- if eq (include "secrets.usesKubernetesSecret" .) "false" }}false
{{- else if and (hasKey . "secret") (hasKey .secret "create") -}}
{{ .secret.create }}
{{- else -}}
true
{{- end -}}
{{- end -}}

{{/* This returns the Kubernetes Secret name for this destination */}}
{{/* Inputs: $ (top level helm data) object (user of the secret, needs name, secret, auth) */}}
{{- define "secrets.kubernetesSecretName" -}}
{{- $secretName := dig "secret" "name" "" .object }}
{{- if $secretName -}}
  {{- $secretName -}}
{{- else -}}
  {{- if contains .Chart.Name .Release.Name }}
    {{- printf "%s-%s" .object.name .Release.Name | trunc 63 | trimSuffix "-" | lower -}}
  {{- else }}
    {{- printf "%s-%s-%s" .object.name .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" | lower -}}
  {{- end }}
{{- end }}
{{- end }}

{{/* This returns the Kubernetes Secret namespace for this destination */}}
{{/* Inputs: $ (top level helm data) object (user of the secret, needs name, secret, auth) */}}
{{- define "secrets.kubernetesSecretNamespace" -}}
{{- $secretNamespace := dig "secret" "namespace" "" .object }}
{{- if $secretNamespace -}}
  {{- $secretNamespace -}}
{{- else -}}
  {{- .Release.Namespace -}}
{{- end }}
{{- end }}
