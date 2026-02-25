{{- define "destinations.prometheus.alloy" }}
{{- with .destination }}
otelcol.exporter.prometheus {{ include "helper.alloy_name" .name | quote }} {
  add_metric_suffixes = {{ .openTelemetryConversion.addMetricSuffixes }}
  resource_to_telemetry_conversion = {{ .openTelemetryConversion.resourceToTelemetryConversion }}
  forward_to = [prometheus.remote_write.{{ include "helper.alloy_name" .name }}.receiver]
}

{{- $hasNamespaceLabelMetricEnrichment := gt (len (dig "metricEnrichment" "namespaceLabels" list .)) 0 }}
{{- $hasPodLabelMetricEnrichment := gt (len (dig "metricEnrichment" "podLabels" list .)) 0 }}
{{- $hasMetricEnrichment := or $hasNamespaceLabelMetricEnrichment $hasPodLabelMetricEnrichment }}
{{- if $hasMetricEnrichment }}
discovery.kubernetes {{ include "helper.alloy_name" .name | quote }} {
  role = "pod"
{{- if not $hasNamespaceLabelMetricEnrichment }}
  selectors {
    role = "pod"
    label = {{ .metricEnrichment.podLabels | join "," | quote }}
  }
{{- else }}
  attach_metadata {
    namespace = true
  }
{{- end }}
}
discovery.relabel {{ include "helper.alloy_name" .name | quote }} {
  targets = discovery.kubernetes.{{ include "helper.alloy_name" .name }}.targets
{{- if $hasPodLabelMetricEnrichment }}
  rule {
    source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_name"]
    regex = "(.+;.+)"
    target_label = "__meta_kubernetes_namespace_pod"
  }
{{- end }}
{{- range $label := .metricEnrichment.podLabels }}
  rule {
    source_labels = [{{ include "pod_label" $label | quote }}]
    target_label = {{ $label | quote }}
  }
{{- end }}
{{- range $label := .metricEnrichment.namespaceLabels }}
  rule {
    source_labels = [{{ include "namespace_label" $label | quote }}]
    target_label = {{ $label | quote }}
  }
{{- end }}
}

prometheus.relabel {{ include "helper.alloy_name" .name | quote }} {
  rule {
    source_labels = ["namespace", "pod"]
    regex = "(.+;.+)"
    target_label = "__meta_kubernetes_namespace_pod"
  }
{{- if $hasNamespaceLabelMetricEnrichment }}
  forward_to = [prometheus.enrich.{{ include "helper.alloy_name" .name }}_ns.receiver]
{{- else if $hasPodLabelMetricEnrichment }}
  forward_to = [prometheus.enrich.{{ include "helper.alloy_name" .name }}_pod.receiver]
{{- end }}
}

{{- if $hasNamespaceLabelMetricEnrichment }}
prometheus.enrich "{{ include "helper.alloy_name" .name }}_ns" {
  targets = discovery.relabel.{{ include "helper.alloy_name" .name }}.output
  target_match_label = "__meta_kubernetes_namespace"
  metrics_match_label = "namespace"
  labels_to_copy = {{ .metricEnrichment.namespaceLabels | toJson }}
{{- if $hasPodLabelMetricEnrichment }}
  forward_to = [prometheus.enrich.{{ include "helper.alloy_name" .name }}_pod.receiver]
{{- else }}
  forward_to = [prometheus.remote_write.{{ include "helper.alloy_name" .name }}.receiver]
{{- end }}
}
{{- end }}

{{- if $hasPodLabelMetricEnrichment }}
prometheus.enrich "{{ include "helper.alloy_name" .name }}_pod" {
  targets = discovery.relabel.{{ include "helper.alloy_name" .name }}.output
  target_match_label = "__meta_kubernetes_namespace_pod"
  labels_to_copy = {{ .metricEnrichment.podLabels | toJson }}
  forward_to = [prometheus.remote_write.{{ include "helper.alloy_name" .name }}.receiver]
}
{{- end }}

{{- end }}

prometheus.remote_write {{ include "helper.alloy_name" .name | quote }} {
  endpoint {
{{- if .urlFrom }} 
    url = {{ .urlFrom }}
{{- else }}
    url = {{ .url | quote }} 
{{- end }}
{{- if .protobufMessage }}
    protobuf_message = {{ .protobufMessage | quote }}
{{- else if (eq (.remoteWriteProtocol | int) 2) }}
    protobuf_message = "io.prometheus.write.v2.Request"
{{- end }}
    headers = {
{{- if ne (include "secrets.authType" .) "sigv4" }}
  {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "tenantId")) "true" }}
      "X-Scope-OrgID" = {{ include "secrets.read" (dict "object" . "key" "tenantId" "nonsensitive" true) }},
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
{{- if .noProxy }}
    no_proxy = {{ .noProxy | quote }}
{{- end }}
{{- if .proxyConnectHeader }}
    proxy_connect_header = {
{{- range $k, $v := .proxyConnectHeader }}
      {{ $k | quote }} = {{ $v | toJson }},
{{- end }}
    }
{{- end }}
{{- if .proxyFromEnvironment }}
    proxy_from_environment = {{ .proxyFromEnvironment }}
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
      proxy_connect_header = {
      {{- range $k, $v := .auth.oauth2.proxyConnectHeader }}
        {{ $k }} = {{ $v | toJson }},
      {{- end }}
      }
      {{- end }}
      {{- if .auth.oauth2.scopes }}
      scopes = {{ .auth.oauth2.scopes | toJson }}
      {{- end }}
      {{- if .auth.oauth2.tokenURL }}
      token_url = {{ .auth.oauth2.tokenURL | quote }}
      {{- end }}
      {{- if .auth.oauth2.tls }}
      tls_config {
        insecure_skip_verify = {{ .auth.oauth2.tls.insecureSkipVerify | default false }}
        {{- if .auth.oauth2.tls.caFile }}
        ca_file = {{ .auth.oauth2.tls.caFile | quote }}
        {{- else if eq (include "secrets.usesSecret" (dict "object" . "key" "auth.oauth2.tls.ca")) "true" }}
        ca_pem = {{ include "secrets.read" (dict "object" . "key" "auth.oauth2.tls.ca" "nonsensitive" true) }}
        {{- end }}
        {{- if .auth.oauth2.tls.certFile }}
        cert_file = {{ .auth.oauth2.tls.certFile | quote }}
        {{- else if eq (include "secrets.usesSecret" (dict "object" . "key" "auth.oauth2.tls.cert")) "true" }}
        cert_pem = {{ include "secrets.read" (dict "object" . "key" "auth.oauth2.tls.cert" "nonsensitive" true) }}
        {{- end }}
        {{- if .auth.oauth2.tls.keyFile }}
        key_file = {{ .auth.oauth2.tls.keyFile | quote }}
        {{- else if eq (include "secrets.usesSecret" (dict "object" . "key" "auth.oauth2.tls.key")) "true" }}
        key_pem = {{ include "secrets.read" (dict "object" . "key" "auth.oauth2.tls.key") }}
        {{- end }}
      }
      {{- end }}
    }
{{- else if eq (include "secrets.authType" .) "sigv4" }}
    sigv4 {
      {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "auth.sigv4.accessKey")) "true" }}
      access_key = {{ include "secrets.read" (dict "object" . "key" "auth.sigv4.accessKey" "nonsensitive" true) }}
      {{- end }}
      {{- if .auth.sigv4.profile }}
      profile = {{ .auth.sigv4.profile | quote }}
      {{- end }}
      {{- if .auth.sigv4.region }}
      region = {{ .auth.sigv4.region | quote }}
      {{- end }}
      {{- if .auth.sigv4.roleArn }}
      role_arn = {{ .auth.sigv4.roleArn | quote }}
      {{- end }}
      {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "auth.sigv4.secretKey")) "true" }}
      secret_key = {{ include "secrets.read" (dict "object" . "key" "auth.sigv4.secretKey") }}
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
    send_native_histograms = {{ .sendNativeHistograms | default false }}

    queue_config {
      capacity = {{ .queueConfig.capacity | default 10000}}
      min_shards = {{ .queueConfig.minShards | default 1 }}
      max_shards = {{ .queueConfig.maxShards | default 50 }}
      max_samples_per_send = {{ .queueConfig.maxSamplesPerSend | default 2000 }}
      batch_send_deadline = {{ .queueConfig.batchSendDeadline | default "5s" | quote }}
      min_backoff = {{ .queueConfig.minBackoff | default "30ms" | quote }}
      max_backoff = {{ .queueConfig.maxBackoff | default "5s" | quote }}
      retry_on_http_429 = {{ .queueConfig.retryOnHttp429 }}
      sample_age_limit = {{ .queueConfig.sampleAgeLimit | default "0s" | quote }}
    }
{{ range $label := .clusterLabels }}
    write_relabel_config {
      source_labels = [{{ include "escape_label" $label | quote }}]
      regex = ""
      replacement = {{ $.Values.cluster.name | quote }}
      target_label = {{ include "escape_label" $label | quote }}
    }
{{- end }}
{{- if .metricEnrichment.podLabels }}
    write_relabel_config {
      regex = "__meta_kubernetes_namespace_pod"
      action = "labeldrop"
    }
{{- end }}
{{- if .metricProcessingRules }}
{{ .metricProcessingRules | indent 4 }}
{{- end }}
  }

  wal {
    truncate_frequency = {{ .writeAheadLog.truncateFrequency | quote }}
    min_keepalive_time = {{ .writeAheadLog.minKeepaliveTime | quote }}
    max_keepalive_time = {{ .writeAheadLog.maxKeepaliveTime | quote }}
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

{{- define "secrets.list.prometheus" -}}
- tenantId
- auth.username
- auth.password
- auth.bearerToken
- auth.oauth2.clientId
- auth.oauth2.clientSecret
- auth.oauth2.tls.ca
- auth.oauth2.tls.cert
- auth.oauth2.tls.key
- auth.sigv4.accessKey
- auth.sigv4.secretKey
- tls.ca
- tls.cert
- tls.key
{{- end -}}

{{- define "destinations.prometheus.alloy.prometheus.metrics.target" }}
{{- $hasNamespaceLabelMetricEnrichment := gt (len (dig "metricEnrichment" "namespaceLabels" list .)) 0 }}
{{- $hasPodLabelMetricEnrichment := gt (len (dig "metricEnrichment" "podLabels" list .)) 0 }}
{{- $hasMetricEnrichment := or $hasNamespaceLabelMetricEnrichment $hasPodLabelMetricEnrichment }}
{{- if $hasMetricEnrichment }}
prometheus.relabel.{{ include "helper.alloy_name" .name }}.receiver
{{- else }}
prometheus.remote_write.{{ include "helper.alloy_name" .name }}.receiver
{{ end -}}
{{ end -}}
{{- define "destinations.prometheus.alloy.otlp.metrics.target" }}otelcol.exporter.prometheus.{{ include "helper.alloy_name" .name }}.input{{ end -}}

{{- define "destinations.prometheus.supports_metrics" }}true{{ end -}}
{{- define "destinations.prometheus.supports_logs" }}false{{ end -}}
{{- define "destinations.prometheus.supports_traces" }}false{{ end -}}
{{- define "destinations.prometheus.supports_profiles" }}false{{ end -}}
{{- define "destinations.prometheus.ecosystem" }}prometheus{{ end -}}
