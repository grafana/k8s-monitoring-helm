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
{{- if eq (include "secrets.usesSecret" (dict "object" . "key" "tenantId")) "true" }}
      "X-Scope-OrgID" = {{ include "secrets.read" (dict "object" . "key" "tenantId" "nonsensitive" true) }},
{{- end }}
{{- range $key, $value := .extraHeaders }}
      {{ $key | quote }} = {{ $value | quote }},
{{- end }}
{{- range $key, $value := .extraHeadersFrom }}
      {{ $key | quote }} = {{ $value }},
{{- end }}
    }

{{- if eq (include "secrets.authType" .) "basic" }}
    basic_auth {
      username = {{ include "secrets.read" (dict "object" . "key" "auth.username" "nonsensitive" true) }}
      password = {{ include "secrets.read" (dict "object" . "key" "auth.password") }}
    }
{{- else if eq (include "secrets.authType" .) "bearerToken" }}
    bearer_token = {{ include "secrets.read" (dict "object" . "key" "auth.bearerToken") }}
{{- end }}

{{- if .tls }}
    tls_config {
      insecure_skip_verify = {{ .tls.insecureSkipVerify | default false }}
      {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "tls.ca")) "true" }}
      ca_pem = {{ include "secrets.read" (dict "object" . "key" "tls.ca" "nonsensitive" true) }}
      {{- end }}
      {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "tls.cert")) "true" }}
      cert_pem = {{ include "secrets.read" (dict "object" . "key" "tls.cert" "nonsensitive" true) }}
      {{- end }}
      {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "tls.key")) "true" }}
      key_pem = {{ include "secrets.read" (dict "object" . "key" "tls.key") }}
      {{- end }}
    }
{{- end }}
  }

  external_labels = {
    cluster = {{ $.Values.cluster.name | quote }},
    k8s_cluster_name = {{ $.Values.cluster.name | quote }},
  }
}
{{- end }}
{{- end }}

{{- define "secrets.list.pyroscope" -}}
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
