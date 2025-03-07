{{- define "destinations.loki.alloy" }}
{{- $defaultValues := "destinations/loki-values.yaml" | .Files.Get | fromYaml }}
{{- with merge .destination $defaultValues }}
otelcol.exporter.loki {{ include "helper.alloy_name" .name | quote }} {
  forward_to = [{{ include "destinations.loki.alloy.loki.logs.target" . }}]
}
{{- if .logProcessingStages }}

loki.process {{ include "helper.alloy_name" .name | quote }} {
{{ .logProcessingStages | indent 2 }}
  forward_to = [loki.write.{{ include "helper.alloy_name" .name }}.receiver]
}
{{- end }}

loki.write {{ include "helper.alloy_name" .name | quote }} {
  endpoint {
{{- if .urlFrom }} 
    url = {{ .urlFrom }}
{{- else }}
    url = {{ .url | quote }} 
{{- end }}
{{- if eq (include "secrets.usesSecret" (dict "object" . "key" "tenantId")) "true" }}
    tenant_id = {{ include "secrets.read" (dict "object" . "key" "tenantId" "nonsensitive" true) }}
{{- end }}
{{- if or .extraHeaders .extraHeadersFrom }}
    headers = {
{{- range $key, $value := .extraHeaders }}
      {{ $key | quote }} = {{ $value | quote }},
{{- end }}
{{- range $key, $value := .extraHeadersFrom }}
      {{ $key | quote }} = {{ $value }},
{{- end }}
    }
{{- end }}
{{- if .proxyURL }}
    proxy_url = {{ .proxyURL | quote }}
{{- end }}
{{- if eq (include "secrets.authType" .) "basic" }}
    basic_auth {
      username = {{ include "secrets.read" (dict "object" . "key" "auth.username" "nonsensitive" true) }}
      password = {{ include "secrets.read" (dict "object" . "key" "auth.password") }}
    }
{{- else if eq (include "secrets.authType" .) "bearerToken" }}
{{- if .auth.bearerTokenFile }}
    bearer_token_file = {{ .auth.bearerTokenFile | quote }}
{{- else }}
    bearer_token = {{ include "secrets.read" (dict "object" . "key" "auth.bearerToken") }}
{{- end }}
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
    "k8s_cluster_name" = {{ $.Values.cluster.name | quote }},
{{- if .extraLabels }}
  {{- range $k, $v := .extraLabels }}
    {{ $k }} = {{ $v | quote }},
  {{- end }}
{{- end }}
{{- if .extraLabelsFrom }}
  {{- range $k, $v := .extraLabelsFrom }}
    {{ $k }} = {{ $v }},
  {{- end }}
{{- end }}
  }
}
{{- end }}
{{- end }}

{{- define "secrets.list.loki" -}}
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

{{- define "destinations.loki.alloy.loki.logs.target" }}
{{- if .logProcessingStages -}}
loki.process.{{ include "helper.alloy_name" .name }}.receiver
{{- else -}}
loki.write.{{ include "helper.alloy_name" .name }}.receiver
{{- end -}}
{{- end -}}
{{- define "destinations.loki.alloy.otlp.logs.target" }}otelcol.exporter.loki.{{ include "helper.alloy_name" .name }}.input{{ end -}}

{{- define "destinations.loki.supports_metrics" }}false{{ end -}}
{{- define "destinations.loki.supports_logs" }}true{{ end -}}
{{- define "destinations.loki.supports_traces" }}false{{ end -}}
{{- define "destinations.loki.supports_profiles" }}false{{ end -}}
{{- define "destinations.loki.ecosystem" }}loki{{ end -}}
