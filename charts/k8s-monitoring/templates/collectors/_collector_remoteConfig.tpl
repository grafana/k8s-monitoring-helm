{{- define "collectors.remoteConfig.alloy" -}}
{{- $remoteConfigValues := (index .Values .collectorName).remoteConfig }}
{{- with merge $remoteConfigValues (dict "type" "remoteConfig" "name" (printf "%s-remote-cfg" .collectorName)) }}
{{- if .enabled }}
{{- if eq (include "secrets.usesKubernetesSecret" .) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" .)) | nindent 0 }}
{{- end }}
remotecfg {
  url = {{ .url | quote }}
{{- if eq (include "secrets.authType" .) "basic" }}
  basic_auth {
    username = {{ include "secrets.read" (dict "object" . "key" "auth.username" "nonsensitive" true) }}
    password = {{ include "secrets.read" (dict "object" . "key" "auth.password") }}
  }
{{- end -}}
{{- if .id }}
  id = {{ .id | quote }}
{{- else }}
  id = "{{ $.Values.cluster.name }}-{{ $.Release.Namespace }}-" + constants.hostname
{{- end }}
  poll_frequency = {{ .pollFrequency | quote }}
  attributes = {
    "cluster" = {{ $.Values.cluster.name | quote }},
    "platform" = "kubernetes",
    "workloadType" = {{ (index $.Values $.collectorName).controller.type | quote }},
{{- range $key, $value := .extraAttributes }}
    {{ $key | quote }} = {{ $value | quote }},
{{- end }}
  }
}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "secrets.list.remoteConfig" -}}
- auth.username
- auth.password
{{- end -}}
