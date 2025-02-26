{{- define "collectors.remoteConfig.alloy" -}}
{{- $remoteConfigValues := (index .Values .collectorName).remoteConfig }}
{{- with merge $remoteConfigValues (dict "type" "remoteConfig" "name" (printf "%s-remote-cfg" .collectorName)) }}
{{- if .enabled }}
{{- if eq (include "secrets.usesKubernetesSecret" .) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" .)) | nindent 0 }}
{{- end }}
remotecfg {
  id = sys.env("GCLOUD_FM_COLLECTOR_ID")
  url = {{ .url | quote }}
{{- if eq (include "secrets.authType" .) "basic" }}
  basic_auth {
    username = {{ include "secrets.read" (dict "object" . "key" "auth.username" "nonsensitive" true) }}
    password = {{ include "secrets.read" (dict "object" . "key" "auth.password") }}
  }
{{- end }}
  poll_frequency = {{ .pollFrequency | quote }}
  attributes = {
    "platform" = "kubernetes",
    "source" = "{{ $.Chart.Name }}",
    "sourceVersion" = "{{ $.Chart.Version }}",
    "release" = "{{ $.Release.Name }}",
    "cluster" = {{ $.Values.cluster.name | quote }},
    "namespace" = {{ $.Release.Namespace | quote }},
    "workloadName" = {{ $.collectorName | quote }},
    "workloadType" = {{ (index $.Values $.collectorName).controller.type | quote }},
{{- range $key, $value := .extraAttributes }}
    {{ $key | quote }} = {{ $value | quote }},
{{- end }}
  }
}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "collectors.validate.remoteConfig" }}
{{- if (index .Values .collectorName).enabled }}
  {{- if (index .Values .collectorName).remoteConfig.enabled }}
    {{- $hasCollectorIdEnv := false }}
    {{- $hasAPIKey := false }}
    {{- range $env := (index .Values .collectorName).alloy.extraEnv }}
      {{- if eq $env.name "GCLOUD_FM_COLLECTOR_ID" }}{{ $hasCollectorIdEnv = true }}{{- end }}
      {{- if eq $env.name "GCLOUD_RW_API_KEY" }}{{ $hasAPIKey = true }}{{- end }}
    {{- end }}
    {{- if not $hasCollectorIdEnv }}
      {{- $msg := list "" "The remote configuration feature requires the environment variable GCLOUD_FM_COLLECTOR_ID to be set. Please set:" }}
      {{- $msg = append $msg (printf "%s:" .collectorName ) }}
      {{- $msg = append $msg "  alloy:" }}
      {{- $msg = append $msg "    extraEnv:" }}
      {{- $msg = append $msg "      - name: GCLOUD_FM_COLLECTOR_ID" }}
      {{- $msg = append $msg "        value: " }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
    {{- if not $hasAPIKey }}
      {{- $msg := list "" "The remote configuration feature requires the environment variable GCLOUD_RW_API_KEY to be set. Please set:" }}
      {{- $msg = append $msg (printf "%s:" .collectorName ) }}
      {{- $msg = append $msg "  alloy:" }}
      {{- $msg = append $msg "    extraEnv:" }}
      {{- $msg = append $msg "      - name: GCLOUD_RW_API_KEY" }}
      {{- $msg = append $msg "        value: <Grafana Cloud Access Policy Token" }}
      {{- $msg = append $msg "OR" }}
      {{- $msg = append $msg "        valueFrom:" }}
      {{- $msg = append $msg "          secretKeyRef:" }}
      {{- $msg = append $msg "            name: <secret name>" }}
      {{- $msg = append $msg "            key: <secret key>" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}

{{- define "secrets.list.remoteConfig" -}}
- auth.username
- auth.password
{{- end -}}
