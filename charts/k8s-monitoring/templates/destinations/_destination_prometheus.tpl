{{- define "destinations.prometheus.alloy" }}
{{- $defaultValues := "destinations/prometheus-values.yaml" | .Files.Get | fromYaml }}
{{- with merge .destination $defaultValues }}
otelcol.exporter.prometheus {{ include "helper.alloy_name" .name | quote }} {
  forward_to = [prometheus.remote_write.{{ include "helper.alloy_name" .name }}.receiver]
}

prometheus.remote_write {{ include "helper.alloy_name" .name | quote }} {
  endpoint {
    url = {{ .url | quote }}
    headers = {
{{- if ne (include "destinations.auth.type" .) "sigv4" }}
  {{- if eq (include "destinations.secret.uses_secret" (dict "destination" . "key" "tenantId")) "true" }}
      "X-Scope-OrgID" = {{ include "destinations.secret.read" (dict "destination" . "key" "tenantId" "nonsensitive" true) }},
  {{- end }}
{{- end }}
{{- range $key, $value := .extraHeaders }}
      {{ $key | quote }} = {{ $value | quote }},
{{- end }}
{{- range $key, $value := .extraHeadersFrom }}
      {{ $key | quote }} = {{ $value }},
{{- end }}
    }
{{- if .proxyURL }}
    proxy_url = {{ .proxyURL | quote }}
{{- end }}
{{- if eq (include "destinations.auth.type" .) "basic" }}
    basic_auth {
      username = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.username" "nonsensitive" true) }}
      password = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.password") }}
    }
{{- else if eq (include "destinations.auth.type" .) "bearerToken" }}
    bearer_token = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.bearerToken") }}
{{- else if eq (include "destinations.auth.type" .) "sigv4" }}
    sigv4 {
      access_key = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.sigv4.accessKey" "nonsensitive" true) }}
      {{- if .auth.sigv4.profile }}
      profile = {{ .auth.sigv4.profile | quote }}
      {{- end }}
      {{- if .auth.sigv4.region }}
      region = {{ .auth.sigv4.region | quote }}
      {{- end }}
      {{- if .auth.sigv4.roleArn }}
      role_arn = {{ .auth.sigv4.roleArn | quote }}
      {{- end }}
      secret_key = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.sigv4.secretKey") }}
    }
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
    send_native_histograms = {{ .sendNativeHistograms | default false }}
{{- if .queueConfig }}
    queue_config {
      capacity = {{ .queueConfig.capacity | default 10000}}
      min_shards = {{ .queueConfig.minShards | default 1 }}
      max_shards = {{ .queueConfig.maxShards | default 50 }}
      max_samples_per_send = {{ .queueConfig.maxSamplesPerSend | default 2000 }}
      batch_send_deadline = {{ .queueConfig.batchSendDeadline | default "5s" | quote }}
      min_backoff = {{ .queueConfig.minBackoff | default "30ms" | quote }}
      max_backoff = {{ .queueConfig.maxBackoff | default "5s" | quote }}
      retry_on_http_429 = {{ .queueConfig.retryOnHttp429 | default true }}
      sample_age_limit = {{ .queueConfig.sampleAgeLimit | default "0s" | quote }}
    }
{{- end }}
    write_relabel_config {
      source_labels = ["cluster"]
      regex = ""
      replacement = {{ $.clusterName | quote }}
      target_label = "cluster"
    }
    write_relabel_config {
      source_labels = ["k8s.cluster.name"]
      regex = ""
      replacement = {{ $.clusterName | quote }}
      target_label = "cluster"
    }
{{- if .metricProcessingRules }}
{{ .metricProcessingRules | indent 4 }}
{{- end }}
  }
{{- if or .extraLabels .extraLabelsFrom }}
  external_labels = {
  {{- range $key, $value := .extraLabels }}
    {{ $key }} = {{ $value | quote }},
  {{- end }}
  {{- range $key, $value := .extraLabelsFrom }}
    {{ $key }} = {{ $value }},
  {{- end }}
  }
{{- end }}
}
{{- end }}
{{- end }}

{{- define "destinations.prometheus.secrets" -}}
- tenantId
- auth.username
- auth.password
- auth.bearerToken
- auth.sigv4.accessKey
- auth.sigv4.secretKey
- tls.ca
- tls.cert
- tls.key
{{- end -}}

{{- define "destinations.prometheus.alloy.prometheus.metrics.target" }}prometheus.remote_write.{{ include "helper.alloy_name" .name }}.receiver{{ end -}}
{{- define "destinations.prometheus.alloy.otlp.metrics.target" }}otelcol.exporter.prometheus.{{ include "helper.alloy_name" .name }}.input{{ end -}}

{{- define "destinations.prometheus.supports_metrics" }}true{{ end -}}
{{- define "destinations.prometheus.supports_logs" }}false{{ end -}}
{{- define "destinations.prometheus.supports_traces" }}false{{ end -}}
{{- define "destinations.prometheus.supports_profiles" }}false{{ end -}}
{{- define "destinations.prometheus.ecosystem" }}prometheus{{ end -}}
