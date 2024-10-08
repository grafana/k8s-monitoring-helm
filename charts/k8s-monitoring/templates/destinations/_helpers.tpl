{{/*Helper function to return the auth type, defaulting to none*/}}
{{/*Inputs: . (destination definition)*/}}
{{- define "destinations.auth.type" }}
{{- if hasKey . "auth" }}{{ .auth.type | default "none" }}{{ else }}none{{ end }}
{{- end }}

{{/*Helper function to determine the secret type*/}}
{{/*Inputs: . (destination definition)*/}}
{{- define "destinations.secret.type" }}
{{- if hasKey . "secret" }}
  {{- if .secret.embed -}}embedded
  {{- else if eq .secret.create false -}}external
  {{- end }}
{{- else -}}
create
{{- end }}
{{- end }}

{{/*Determine if a ___From field has been defined for a secret value*/}}
{{/*Inputs: destination (destination definition), key (path to secret value)*/}}
{{- define "destinations.secret.from" -}}
{{- $value := .destination -}}
{{- range $pathPart := (regexSplit "\\." (printf "%sFrom" .key) -1) -}} {{/* "path.to.auth.password" --> ["path", "to", "auth" "passwordFrom"] */}}
{{- if hasKey $value $pathPart -}}
  {{- $value = (index $value $pathPart) -}}
{{- else -}}
  {{- $value = "" -}}
  {{- break -}}
{{- end -}}
{{- end -}}
{{- $value -}}
{{- end -}}

{{/*Determine the key to access a secret value within a secret component*/}}
{{/*Inputs: destination (destination definition), key (path to secret value)*/}}
{{- define "destinations.secret.key" -}}
{{- $defaultKey := (( regexSplit "\\." .key -1) | last) -}}    {{/* "path.to.auth.password" --> "password" */}}
{{- $value := .destination -}}
{{- range $pathPart := (regexSplit "\\." (printf "%sKey" .key) -1) -}}
{{- if hasKey $value $pathPart -}}
  {{- $value = (index $value $pathPart) -}}
{{- else -}}
  {{- $value = $defaultKey -}}
  {{- break -}}
{{- end -}}
{{- end -}}
{{- $value -}}
{{- end -}}

{{/*Determine the path to the secret value*/}}
{{/*Inputs: destination (destination definition), key (path to secret value)*/}}
{{- define "destinations.secret.value" }}
{{- $value := .destination -}}
{{- range $pathPart := (regexSplit "\\." .key -1) -}}
{{- if hasKey $value $pathPart -}}
  {{- $value = (index $value $pathPart) -}}
{{- else -}}
  {{- $value = "" -}}
  {{- break -}}
{{- end -}}
{{- end -}}
{{- $value -}}
{{- end }}

{{/*Build the alloy command to read a secret value*/}}
{{/*Inputs: destination (destination definition), key (path to secret value), nonsensitive*/}}
{{- define "destinations.secret.read" }}
{{- $credRef := include "destinations.secret.from" . -}}
{{- if $credRef -}}
{{ $credRef }}
{{- else if eq (include "destinations.secret.type" .destination) "embedded" -}}
{{ include "destinations.secret.value" (dict "destination" .destination "key" .key) | quote }}
{{- else if eq (include "destinations.secret.uses_k8s_secret" .destination) "true" -}}
{{- $credKey := include "destinations.secret.key" (dict "destination" .destination "key" .key) -}}
{{- if .nonsensitive -}}
nonsensitive(remote.kubernetes.secret.{{ include "helper.alloy_name" .destination.name }}.data[{{ $credKey | quote }}])
{{- else -}}
remote.kubernetes.secret.{{ include "helper.alloy_name" .destination.name }}.data[{{ $credKey | quote }}]
{{- end -}}
{{- end -}}
{{- end -}}

{{/*Determines if the destination will reference a secret value*/}}
{{/*Inputs: destination (destination definition), key (path to secret value), nonsensitive*/}}
{{- define "destinations.secret.uses_secret" -}}
{{- if eq (include "destinations.secret.read" .) "" }}false{{- else -}}true{{- end -}}
{{- end -}}

{{/*Determines if the destination will reference a Kubernetes secret*/}}
{{/*Inputs: . (destination definition)*/}}
{{- define "destinations.secret.uses_k8s_secret" -}}
{{- $secretType := (include "destinations.secret.type" .) }}
{{- if eq $secretType "embedded" -}}false
{{- else -}}
  {{- $usesK8sSecret := false }}
  {{- range $secret := include (printf "destinations.%s.secrets" .type) . | fromYamlArray }}
    {{- $ref := include "destinations.secret.from" (dict "destination" $ "key" $secret) -}}
    {{- $key := include "destinations.secret.key" (dict "destination" $ "key" $secret) -}}
    {{- $value := include "destinations.secret.value" (dict "destination" $ "key" $secret) -}}
    {{- if or (and (eq $secretType "external") $key) (and $value (not $ref)) }}
      {{- $usesK8sSecret = true }}
    {{- end }}
  {{- end }}
{{- $usesK8sSecret }}
{{- end -}}
{{- end -}}

{{/*Determines if the destination will create a Kubernetes secret*/}}
{{/*Inputs: . (destination definition)*/}}
{{- define "destinations.secret.create_k8s_secret" -}}
{{- if eq (include "destinations.secret.uses_k8s_secret" .) "false" }}false
{{- else if and (hasKey . "secret") (hasKey .secret "create") -}}
{{ .secret.create }}
{{- else -}}
true
{{- end -}}
{{- end -}}

{{/* This returns the Kubernetes Secret name for this destination */}}
{{/* Inputs: destination (destination definition) Release (Release object) Chart (Chart object) */}}
{{- define "destinations.secret.k8s_secret_name" -}}

{{- if and (hasKey .destination "secret") (hasKey .destination.secret "name") (not (empty .destination.secret.name)) -}}
{{ .destination.secret.name }}
{{- else -}}

{{- if contains .Chart.Name .Release.Name }}
{{- printf "%s-%s" .destination.name .Release.Name | trunc 63 | trimSuffix "-" | lower -}}
{{- else }}
{{- printf "%s-%s-%s" .destination.name .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" | lower -}}
{{- end }}

{{- end }}
{{- end }}

{{/* This returns the Kubernetes Secret namespace for this destination */}}
{{/* Inputs: destination (destination definition) Release (Release object) */}}
{{- define "destinations.secret.k8s_secret_namespace" -}}
{{- if and (hasKey .destination "secret") (hasKey .destination.secret "namespace") (not (empty .destination.secret.namespace)) -}}
{{- .destination.secret.namespace -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end }}
{{- end }}
