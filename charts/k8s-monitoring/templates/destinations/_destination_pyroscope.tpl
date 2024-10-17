{{- define "destinations.pyroscope.alloy" }}
{{- $defaultValues := "destinations/pyroscope-values.yaml" | .Files.Get | fromYaml }}
{{- with merge .destination $defaultValues }}
pyroscope.write {{ include "helper.alloy_name" .name | quote }} {
  endpoint {
{{- if .urlFrom }} 
    url = {{ .urlFrom }}
{{- else }}
    url = {{ .url | quote }} 
{{- end }}
    headers = {
{{- if eq (include "destinations.secret.uses_secret" (dict "destination" . "key" "tenantId")) "true" }}
      "X-Scope-OrgID" = {{ include "destinations.secret.read" (dict "destination" . "key" "tenantId" "nonsensitive" true) }},
{{- end }}
{{- range $key, $value := .extraHeaders }}
      {{ $key | quote }} = {{ $value | quote }},
{{- end }}
{{- range $key, $value := .extraHeadersFrom }}
      {{ $key | quote }} = {{ $value }},
{{- end }}
    }

{{- if eq (include "destinations.auth.type" .) "basic" }}
    basic_auth {
      username = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.username" "nonsensitive" true) }}
      password = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.password") }}
    }
{{- else if eq (include "destinations.auth.type" .) "bearerToken" }}
    bearer_token = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.bearerToken") }}
{{- end }}

{{- if .tls }}
    tls_config {
      insecure_skip_verify = {{ .tls.insecureSkipVerify | default false }}
      {{- if eq (include "destinations.secret.uses_secret" (dict "destination" . "key" "tls.ca")) "true" }}
      ca_pem = {{ include "destinations.secret.read" (dict "destination" . "key" "tls.ca" "nonsensitive" true) }}
      {{- end }}
      {{- if eq (include "destinations.secret.uses_secret" (dict "destination" . "key" "tls.cert")) "true" }}
      cert_pem = {{ include "destinations.secret.read" (dict "destination" . "key" "tls.cert" "nonsensitive" true) }}
      {{- end }}
      {{- if eq (include "destinations.secret.uses_secret" (dict "destination" . "key" "tls.key")) "true" }}
      key_pem = {{ include "destinations.secret.read" (dict "destination" . "key" "tls.key") }}
      {{- end }}
    }
{{- end }}
  }

  external_labels = {
    cluster = {{ $.clusterName | quote }},
  }
}
{{- end }}
{{- end }}

{{- define "destinations.pyroscope.secrets" -}}
- tenantId
- auth.username
- auth.password
- auth.bearerToken
{{- end -}}

{{- define "destinations.pyroscope.alloy.pyroscope.profiles.target" }}pyroscope.write.{{ include "helper.alloy_name" .name }}.receiver{{ end -}}

{{- define "destinations.pyroscope.supports_metrics" }}false{{ end -}}
{{- define "destinations.pyroscope.supports_logs" }}false{{ end -}}
{{- define "destinations.pyroscope.supports_traces" }}false{{ end -}}
{{- define "destinations.pyroscope.supports_profiles" }}true{{ end -}}
{{- define "destinations.pyroscope.ecosystem" }}pyroscope{{ end -}}
