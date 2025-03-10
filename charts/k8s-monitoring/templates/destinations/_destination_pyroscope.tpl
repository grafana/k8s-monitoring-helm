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
{{- else if eq (include "secrets.authType" .) "oauth2" }}
    oauth2 {
      client_id = {{ include "secrets.read" (dict "object" . "key" "auth.oauth2.clientId" "nonsensitive" true) }}
      {{- if eq .auth.oauth2.clientSecretFile "" }}
      client_secret = {{ include "secrets.read" (dict "object" . "key" "auth.oauth2.clientSecret") }}
      {{- else }}
      client_secret_file = {{ .auth.oauth2.clientSecretFile | quote }}
      {{- end }}
      {{- if .auth.oauth2.endpointParams }}
      endpoint_params = {
      {{- range $k, $v := .auth.oauth2.endpointParams }}
        {{ $k }} = {{ $v | toJson }},
      {{- end }}
      }
      {{- end }}
      {{- if .auth.oauth2.proxyURL }}
      proxy_url = {{ .auth.oauth2.proxyURL | quote }}
      {{- end }}
      {{- if .auth.oauth2.noProxy }}
      no_proxy = {{ .auth.oauth2.noProxy | quote }}
      {{- end }}
      {{- if .auth.oauth2.proxyFromEnvironment }}
      proxyFromEnvironment = {{ .auth.oauth2.proxyFromEnvironment }}
      {{- end }}
      {{- if .auth.oauth2.proxyConnectHeader }}
      proxy_connect_header = {{ .auth.oauth2.proxyConnectHeader | toJson }}
      {{- end }}
      {{- if .auth.oauth2.scopes }}
      scopes = {{ .auth.oauth2.scopes | toJson }}
      {{- end }}
      {{- if .auth.oauth2.tokenURL }}
      token_url = {{ .auth.oauth2.tokenURL | quote }}
      {{- end }}
    }
{{- end }}

{{- if .tls }}
    tls_config {
      insecure_skip_verify = {{ .tls.insecureSkipVerify | default false }}
      {{- if .tls.caFile }}
      ca_file = {{ .tls.caFile | quote }}
      {{- else if eq (include "secrets.usesSecret" (dict "object" . "key" "tls.ca")) "true" }}
      ca_pem = {{ include "secrets.read" (dict "object" . "key" "tls.ca" "nonsensitive" true) }}
      {{- end }}
      {{- if .tls.certFile }}
      cert_file = {{ .tls.certFile | quote }}
      {{- else if eq (include "secrets.usesSecret" (dict "object" . "key" "tls.cert")) "true" }}
      cert_pem = {{ include "secrets.read" (dict "object" . "key" "tls.cert" "nonsensitive" true) }}
      {{- end }}
      {{- if .tls.keyFile }}
      key_file = {{ .tls.keyFile | quote }}
      {{- else if eq (include "secrets.usesSecret" (dict "object" . "key" "tls.key")) "true" }}
      key_pem = {{ include "secrets.read" (dict "object" . "key" "tls.key") }}
      {{- end }}
    }
{{- end }}
    min_backoff_period = {{ .minBackoffPeriod | quote }}
    max_backoff_period = {{ .maxBackoffPeriod | quote }}
    max_backoff_retries = {{ .maxBackoffRetries | quote }}
  }

  external_labels = {
    cluster = {{ $.Values.cluster.name | quote }},
    k8s_cluster_name = {{ $.Values.cluster.name | quote }},
  {{- range $key, $value := .extraLabels }}
    {{ $key }} = {{ $value | quote }},
  {{- end }}
  {{- range $key, $value := .extraLabelsFrom }}
    {{ $key }} = {{ $value }},
  {{- end }}
  }
}
{{- end }}
{{- end }}

{{- define "secrets.list.pyroscope" -}}
- tenantId
- auth.username
- auth.password
- auth.bearerToken
- auth.oauth2.clientId
- auth.oauth2.clientSecret
- tls.ca
- tls.cert
- tls.key
{{- end -}}

{{- define "destinations.pyroscope.alloy.pyroscope.profiles.target" }}pyroscope.write.{{ include "helper.alloy_name" .name }}.receiver{{ end -}}

{{- define "destinations.pyroscope.supports_metrics" }}false{{ end -}}
{{- define "destinations.pyroscope.supports_logs" }}false{{ end -}}
{{- define "destinations.pyroscope.supports_traces" }}false{{ end -}}
{{- define "destinations.pyroscope.supports_profiles" }}true{{ end -}}
{{- define "destinations.pyroscope.ecosystem" }}pyroscope{{ end -}}
