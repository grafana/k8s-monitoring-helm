{{/* Print a Prometheus destination Alloy config components */}}
{{/* Inputs: . (root object),  destination (string, name of destination), destinationName (name of this destination) */}}
{{- define "destinations.prometheus.alloy" }}
{{- with .destination }}
otelcol.exporter.prometheus {{ include "helper.alloy_name" $.destinationName | quote }} {
  add_metric_suffixes = {{ .openTelemetryConversion.addMetricSuffixes }}
  resource_to_telemetry_conversion = {{ .openTelemetryConversion.resourceToTelemetryConversion }}
  forward_to = [prometheus.remote_write.{{ include "helper.alloy_name" $.destinationName }}.receiver]
} // otelcol.exporter.prometheus "{{ include "helper.alloy_name" $.destinationName }}"

{{- $hasNamespaceLabelMetricEnrichment := gt (len (dig "metricEnrichment" "namespaceLabels" list .)) 0 }}
{{- $hasPodLabelMetricEnrichment := gt (len (dig "metricEnrichment" "podLabels" list .)) 0 }}
{{- $hasMetricEnrichment := or $hasNamespaceLabelMetricEnrichment $hasPodLabelMetricEnrichment }}
{{- if $hasMetricEnrichment }}
discovery.kubernetes {{ include "helper.alloy_name" $.destinationName | quote }} {
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
} // discovery.kubernetes "{{ include "helper.alloy_name" $.destinationName }}"
discovery.relabel {{ include "helper.alloy_name" $.destinationName | quote }} {
  targets = discovery.kubernetes.{{ include "helper.alloy_name" $.destinationName }}.targets
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
} // discovery.relabel "{{ include "helper.alloy_name" $.destinationName }}"

prometheus.relabel {{ include "helper.alloy_name" $.destinationName | quote }} {
  rule {
    source_labels = ["namespace", "pod"]
    regex = "(.+;.+)"
    target_label = "__meta_kubernetes_namespace_pod"
  }
{{- if $hasNamespaceLabelMetricEnrichment }}
  forward_to = [prometheus.enrich.{{ include "helper.alloy_name" $.destinationName }}_ns.receiver]
{{- else if $hasPodLabelMetricEnrichment }}
  forward_to = [prometheus.enrich.{{ include "helper.alloy_name" $.destinationName }}_pod.receiver]
{{- end }}
} // prometheus.relabel "{{ include "helper.alloy_name" $.destinationName }}"

{{- if $hasNamespaceLabelMetricEnrichment }}
prometheus.enrich "{{ include "helper.alloy_name" $.destinationName }}_ns" {
  targets = discovery.relabel.{{ include "helper.alloy_name" $.destinationName }}.output
  target_match_label = "__meta_kubernetes_namespace"
  metrics_match_label = "namespace"
  labels_to_copy = {{ .metricEnrichment.namespaceLabels | toJson }}
{{- if $hasPodLabelMetricEnrichment }}
  forward_to = [prometheus.enrich.{{ include "helper.alloy_name" $.destinationName }}_pod.receiver]
{{- else }}
  forward_to = [prometheus.remote_write.{{ include "helper.alloy_name" $.destinationName }}.receiver]
{{- end }}
} // prometheus.enrich "{{ include "helper.alloy_name" $.destinationName }}_ns"
{{- end }}

{{- if $hasPodLabelMetricEnrichment }}
prometheus.enrich "{{ include "helper.alloy_name" $.destinationName }}_pod" {
  targets = discovery.relabel.{{ include "helper.alloy_name" $.destinationName }}.output
  target_match_label = "__meta_kubernetes_namespace_pod"
  labels_to_copy = {{ .metricEnrichment.podLabels | toJson }}
  forward_to = [prometheus.remote_write.{{ include "helper.alloy_name" $.destinationName }}.receiver]
} // prometheus.enrich "{{ include "helper.alloy_name" $.destinationName }}_pod"
{{- end }}

{{- end }}

prometheus.remote_write {{ include "helper.alloy_name" $.destinationName | quote }} {
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
  {{- if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tenantId")) "true" }}
      "X-Scope-OrgID" = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "tenantId" "nonsensitive" true) }},
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
      username = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.username" "nonsensitive" true) }}
      password = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.password") }}
    }
{{- else if eq (include "secrets.authType" .) "bearerToken" }}
{{- if .auth.bearerTokenFile }}
    bearer_token_file = {{ .auth.bearerTokenFile | quote }}
{{- else }}
    bearer_token = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.bearerToken") }}
{{- end }}
{{- else if eq (include "secrets.authType" .) "oauth2" }}
    oauth2 {
      client_id = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.oauth2.clientId" "nonsensitive" true) }}
      {{- if eq .auth.oauth2.clientSecretFile "" }}
      client_secret = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.oauth2.clientSecret") }}
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
        {{- else if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "auth.oauth2.tls.ca")) "true" }}
        ca_pem = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.oauth2.tls.ca" "nonsensitive" true) }}
        {{- end }}
        {{- if .auth.oauth2.tls.certFile }}
        cert_file = {{ .auth.oauth2.tls.certFile | quote }}
        {{- else if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "auth.oauth2.tls.cert")) "true" }}
        cert_pem = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.oauth2.tls.cert" "nonsensitive" true) }}
        {{- end }}
        {{- if .auth.oauth2.tls.keyFile }}
        key_file = {{ .auth.oauth2.tls.keyFile | quote }}
        {{- else if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "auth.oauth2.tls.key")) "true" }}
        key_pem = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.oauth2.tls.key") }}
        {{- end }}
      }
      {{- end }}
    }
{{- else if eq (include "secrets.authType" .) "sigv4" }}
    sigv4 {
      {{- if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "auth.sigv4.accessKey")) "true" }}
      access_key = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.sigv4.accessKey" "nonsensitive" true) }}
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
      {{- if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "auth.sigv4.secretKey")) "true" }}
      secret_key = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.sigv4.secretKey") }}
      {{- end }}
    }
{{- end }}

{{- if .tls }}
    tls_config {
      insecure_skip_verify = {{ .tls.insecureSkipVerify | default false }}
      {{- if .tls.caFile }}
      ca_file = {{ .tls.caFile | quote }}
      {{- else if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tls.ca")) "true" }}
      ca_pem = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "tls.ca" "nonsensitive" true) }}
      {{- end }}
      {{- if .tls.certFile }}
      cert_file = {{ .tls.certFile | quote }}
      {{- else if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tls.cert")) "true" }}
      cert_pem = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "tls.cert" "nonsensitive" true) }}
      {{- end }}
      {{- if .tls.keyFile }}
      key_file = {{ .tls.keyFile | quote }}
      {{- else if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tls.key")) "true" }}
      key_pem = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "tls.key") }}
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
{{- if or .clusterLabels .extraLabels .extraLabelsFrom }}
  external_labels = {
  {{- range $label := .clusterLabels }}
    {{ include "escape_label" $label | quote }} = {{ $.Values.cluster.name | quote }},
  {{- end }}
  {{- range $key, $value := .extraLabels }}
    {{ $key }} = {{ $value | quote }},
  {{- end }}
  {{- range $key, $value := .extraLabelsFrom }}
    {{ $key }} = {{ $value }},
  {{- end }}
  }
{{- end }}
} // prometheus.remote_write "{{ include "helper.alloy_name" $.destinationName }}"
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
{{- $hasNamespaceLabelMetricEnrichment := gt (len (dig "metricEnrichment" "namespaceLabels" list .destination)) 0 }}
{{- $hasPodLabelMetricEnrichment := gt (len (dig "metricEnrichment" "podLabels" list .destination)) 0 }}
{{- $hasMetricEnrichment := or $hasNamespaceLabelMetricEnrichment $hasPodLabelMetricEnrichment }}
{{- if $hasMetricEnrichment }}
prometheus.relabel.{{ include "helper.alloy_name" $.destinationName }}.receiver
{{- else }}
prometheus.remote_write.{{ include "helper.alloy_name" $.destinationName }}.receiver
{{ end -}}
{{ end -}}
{{- define "destinations.prometheus.alloy.otlp.metrics.target" }}otelcol.exporter.prometheus.{{ include "helper.alloy_name" $.destinationName }}.input{{ end -}}

{{- define "destinations.prometheus.supports_metrics" }}true{{ end -}}
{{- define "destinations.prometheus.supports_logs" }}false{{ end -}}
{{- define "destinations.prometheus.supports_traces" }}false{{ end -}}
{{- define "destinations.prometheus.supports_profiles" }}false{{ end -}}
{{- define "destinations.prometheus.ecosystem" }}prometheus{{ end -}}

{{/* Renders a mimir.rules.kubernetes block for one prometheus destination, gated to a single collector. */}}
{{/* Inputs: . (root context with Values), destination (merged destination config), destinationName (string), collectorName (string) */}}
{{- define "destinations.prometheus.rules.alloy" }}
{{- with .destination }}
{{- if and .rules .rules.enabled }}
{{- $rulesCollector := .rules.collector }}
{{- if not $rulesCollector }}
  {{- $enabledCollectors := include "collectors.list.enabled" $ | fromYamlArray }}
  {{- if $enabledCollectors }}{{ $rulesCollector = index $enabledCollectors 0 }}{{- end }}
{{- end }}
{{- if eq $rulesCollector $.collectorName }}
mimir.rules.kubernetes {{ include "helper.alloy_name" $.destinationName | quote }} {
{{- if .rules.addressFrom }}
  address = {{ .rules.addressFrom }}
{{- else if .rules.address }}
  address = {{ .rules.address | quote }}
{{- else if .urlFrom }}
  address = {{ .urlFrom }}
{{- else }}
  address = {{ .url | quote }}
{{- end }}
{{- if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tenantId")) "true" }}
  tenant_id = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "tenantId" "nonsensitive" true) }}
{{- end }}
  sync_interval = {{ .rules.syncInterval | quote }}
  mimir_namespace_prefix = {{ .rules.mimirNamespacePrefix | quote }}
{{- if .rules.useLegacyRoutes }}
  use_legacy_routes = true
{{- end }}
{{- if ne .rules.prometheusHttpPrefix "/prometheus" }}
  prometheus_http_prefix = {{ .rules.prometheusHttpPrefix | quote }}
{{- end }}

{{- if eq (include "secrets.authType" .) "basic" }}
  basic_auth {
    username = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.username" "nonsensitive" true) }}
    password = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.password") }}
  }
{{- else if eq (include "secrets.authType" .) "bearerToken" }}
  authorization {
    type = "Bearer"
{{- if .auth.bearerTokenFile }}
    credentials_file = {{ .auth.bearerTokenFile | quote }}
{{- else }}
    credentials = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.bearerToken") }}
{{- end }}
  }
{{- else if eq (include "secrets.authType" .) "oauth2" }}
  oauth2 {
    client_id = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.oauth2.clientId" "nonsensitive" true) }}
{{- if eq .auth.oauth2.clientSecretFile "" }}
    client_secret = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "auth.oauth2.clientSecret") }}
{{- else }}
    client_secret_file = {{ .auth.oauth2.clientSecretFile | quote }}
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
{{- $hasTLS := false }}
{{- if .tls.insecureSkipVerify }}{{ $hasTLS = true }}{{- end }}
{{- if .tls.caFile }}{{ $hasTLS = true }}{{- end }}
{{- if .tls.certFile }}{{ $hasTLS = true }}{{- end }}
{{- if .tls.keyFile }}{{ $hasTLS = true }}{{- end }}
{{- if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tls.ca")) "true" }}{{ $hasTLS = true }}{{- end }}
{{- if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tls.cert")) "true" }}{{ $hasTLS = true }}{{- end }}
{{- if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tls.key")) "true" }}{{ $hasTLS = true }}{{- end }}
{{- if $hasTLS }}
  tls_config {
    insecure_skip_verify = {{ .tls.insecureSkipVerify | default false }}
{{- if .tls.caFile }}
    ca_file = {{ .tls.caFile | quote }}
{{- else if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tls.ca")) "true" }}
    ca_pem = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "tls.ca" "nonsensitive" true) }}
{{- end }}
{{- if .tls.certFile }}
    cert_file = {{ .tls.certFile | quote }}
{{- else if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tls.cert")) "true" }}
    cert_pem = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "tls.cert" "nonsensitive" true) }}
{{- end }}
{{- if .tls.keyFile }}
    key_file = {{ .tls.keyFile | quote }}
{{- else if eq (include "secrets.usesSecret" (dict "object" . "name" $.destinationName "key" "tls.key")) "true" }}
    key_pem = {{ include "secrets.read" (dict "object" . "name" $.destinationName "key" "tls.key") }}
{{- end }}
  }
{{- end }}
{{- end }}

{{- if .proxyURL }}
  proxy_url = {{ .proxyURL | quote }}
{{- end }}

{{- range $namespace := .rules.namespaces }}
  rule_namespace {
    name = {{ $namespace | quote }}
  }
{{- end }}

{{- if or .rules.namespaceLabelSelectors .rules.namespaceLabelExpressions }}
  rule_namespace_selector {
{{- if .rules.namespaceLabelSelectors }}
    match_labels = {
{{- range $key, $value := .rules.namespaceLabelSelectors }}
      {{ $key | quote }} = {{ $value | quote }},
{{- end }}
    }
{{- end }}
{{- range $expression := .rules.namespaceLabelExpressions }}
    match_expression {
      key = {{ $expression.key | quote }}
      operator = {{ $expression.operator | quote }}
      {{ if $expression.values }}values = {{ $expression.values | toJson }}{{ end }}
    }
{{- end }}
  }
{{- end }}

{{- if or .rules.labelSelectors .rules.labelExpressions }}
  rule_selector {
{{- if .rules.labelSelectors }}
    match_labels = {
{{- range $key, $value := .rules.labelSelectors }}
      {{ $key | quote }} = {{ $value | quote }},
{{- end }}
    }
{{- end }}
{{- range $expression := .rules.labelExpressions }}
    match_expression {
      key = {{ $expression.key | quote }}
      operator = {{ $expression.operator | quote }}
      {{ if $expression.values }}values = {{ $expression.values | toJson }}{{ end }}
    }
{{- end }}
  }
{{- end }}
{{- if .rules.extraArguments }}
{{ .rules.extraArguments | indent 2 }}
{{- end }}
} // mimir.rules.kubernetes "{{ include "helper.alloy_name" $.destinationName }}"
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
