{{- define "collectors.remoteConfig.alloy" -}}
{{- with (index .Values .collectorName).remoteConfig }}
{{- if .enabled }}
remotecfg {
  url = {{ .url | quote }}
{{- if eq .auth.type "basic" }}
  basic_auth {
    username = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.username" "nonsensitive" true) }}
    password = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.password") }}
  }
{{- end -}}
{{- if .id }}
  id = {{ .id | quote }}
{{- else }}
  id = "{{ $.Values.cluster.name }}-{{ $.Release.Namespace }}-" + constants.hostname
{{- end -}}
  poll_frequency = {{ .pollFrequency | quote }}
  attributes = {
    "cluster" = {{ $.Values.cluster.name | quote }},
    "platform" = "kubernetes",
    "workloadType": {{ (index $.Values $.collectorName).controller.type | quote }},
{{- range $key, $value := .extraAttributes }}
    {{ $key | quote }} = {{ $value | quote }},
{{- end -}}
  }
}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "collectors.remoteConfig.secrets" -}}
- auth.username
- auth.password
{{- end -}}
