{{- define "destinations.faro.alloy" }}
{{- with .destination }}

{{/*
otelcol.receiver.loki {{ include "helper.alloy_name" .name | quote }} {
  output {
    logs = [{{ include "destinations.faro.alloy.otlp.logs.target" . | trim }}]
  }
}
*/}}

otelcol.processor.attributes {{ include "helper.alloy_name" .name | quote }} {
{{- range $action := .processors.attributes.actions }}
  action {
    key = {{ $action.key | quote }}
    action = {{ $action.action | quote }}
    {{- if $action.value }}
    value = {{ $action.value | quote }}
    {{- else if $action.valueFrom }}
    value = {{ $action.valueFrom }}
    {{- end }}
    {{- if $action.pattern }}
    pattern = {{ $action.pattern | quote }}
    {{- end }}
    {{- if $action.fromAttribute }}
    from_attribute = {{ $action.fromAttribute | quote }}
    {{- end }}
    {{- if $action.fromContext }}
    from_context = {{ $action.fromContext | quote }}
    {{- end }}
    {{- if $action.convertedType }}
    converted_type = {{ $action.convertedType | quote }}
    {{- end }}
  }
{{- end }}
  output {
    logs = [otelcol.processor.transform.{{ include "helper.alloy_name" .name }}.input]
    traces = [otelcol.processor.transform.{{ include "helper.alloy_name" .name }}.input]
  }
}

otelcol.processor.transform {{ include "helper.alloy_name" .name | quote }} {
  error_mode = {{ .processors.transform.errorMode | quote }}
  {{/*
  statements {
    log = [
{{- range $label := .clusterLabels }}
      `set(attributes[{{ $label | quote }}], {{ $.Values.cluster.name | quote }})`,
{{- end }}
{{- range $transform := .processors.transform.logs }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
    trace = [
{{- range $label := .clusterLabels }}
      `set(attributes[{{ $label | quote }}], {{ $.Values.cluster.name | quote }})`,
{{- end }}
{{- range $transform := .processors.transform.traces }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
  */}}

{{ if .processors.filters.enabled }}

  output {
    logs = [otelcol.processor.filter.{{ include "helper.alloy_name" .name }}.input]
    traces = [otelcol.processor.filter.{{ include "helper.alloy_name" .name }}.input]
  }
}

otelcol.processor.filter {{ include "helper.alloy_name" .name | quote }} {
  error_mode = {{ .processors.filters.errorMode | quote }}

{{- if .processors.filters.logs.logRecord }}
  logs {
    log_record = [
{{- range $filter := .processors.filters.logs.logRecord }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if or .processors.filters.traces.span .processors.filters.traces.spanevent }}
  traces {
{{- if .processors.filters.traces.span }}
    span = [
{{- range $filter := .processors.filters.traces.span }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
{{- end }}
{{- if .processors.filters.traces.spanevent }}
    spanevent = [
{{- range $filter := .processors.filters.traces.spanevent }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
{{- end }}
  }
{{- end }}
{{- end }}

{{- if .processors.batch.enabled -}}
  output {
    logs = [otelcol.processor.batch.{{ include "helper.alloy_name" .name }}.input]
    traces = [otelcol.processor.batch.{{ include "helper.alloy_name" .name }}.input]
  }
}

otelcol.processor.batch {{ include "helper.alloy_name" .name | quote }} {
  timeout = {{ .processors.batch.timeout | quote }}
  send_batch_size = {{ .processors.batch.size | int }}
  send_batch_max_size = {{ .processors.batch.maxSize | int }}

{{- end }}
{{- if .processors.memoryLimiter.enabled }}
  output {
    logs = [otelcol.processor.memory_limiter.{{ include "helper.alloy_name" .name }}.input]
    traces = [otelcol.processor.memory_limiter.{{ include "helper.alloy_name" .name }}.input]
  }
}

otelcol.processor.memory_limiter {{ include "helper.alloy_name" .name | quote }} {
  check_interval = {{ .processors.memoryLimiter.checkInterval | quote }}
  limit = {{ .processors.memoryLimiter.limit | quote }}

{{- end }}
  output {
    logs = [otelcol.exporter.faro.{{ include "helper.alloy_name" .name }}.input]
    traces = [otelcol.exporter.faro.{{ include "helper.alloy_name" .name }}.input]
  }
}

otelcol.exporter.faro {{ include "helper.alloy_name" .name | quote }} {
  client {
{{- if .urlFrom }}
    endpoint = {{ .urlFrom }}
{{- else }}
    endpoint = {{ .url | quote }}
{{- end }}
{{- if .proxyURL }}
    proxy_url = {{ .proxyURL | quote }}
{{- end }}
{{- if eq .auth.type "basic" }}
    auth = otelcol.auth.basic.{{ include "helper.alloy_name" .name }}.handler
{{- else if eq .auth.type "bearerToken" }}
    auth = otelcol.auth.bearer.{{ include "helper.alloy_name" .name }}.handler
{{- else if eq .auth.type "oauth2" }}
    auth = otelcol.auth.oauth2.{{ include "helper.alloy_name" .name }}.handler
{{- else if eq .auth.type "sigv4" }}
    auth = otelcol.auth.sigv4.{{ include "helper.alloy_name" .name }}.handler
{{- end }}
{{- if or (eq (include "secrets.usesSecret" (dict "object" . "key" "tenantId")) "true") .extraHeaders .extraHeadersFrom }}
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
{{- end }}
{{- if .readBufferSize }}
    read_buffer_size = {{ .readBufferSize | quote }}
{{- end }}
{{- if .writeBufferSize }}
    write_buffer_size = {{ .writeBufferSize | quote }}
{{- end }}

{{- if .tls }}
    tls {
      insecure = {{ .tls.insecure | default false }}
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
  }

  retry_on_failure {
    enabled = {{ .retryOnFailure.enabled }}
    initial_interval = {{ .retryOnFailure.initialInterval | quote }}
    max_interval = {{ .retryOnFailure.maxInterval | quote }}
    max_elapsed_time = {{ .retryOnFailure.maxElapsedTime | quote }}
  }
}
{{- if eq (include "secrets.authType" .) "basic" }}

otelcol.auth.basic {{ include "helper.alloy_name" .name | quote }} {
  username = {{ include "secrets.read" (dict "object" . "key" "auth.username" "nonsensitive" true) }}
  password = {{ include "secrets.read" (dict "object" . "key" "auth.password") }}
}
{{- else if eq (include "secrets.authType" .) "bearerToken" }}
{{- if .auth.bearerTokenFile }}

local.file {{ include "helper.alloy_name" .name | quote }} {
  filename = {{ .auth.bearerTokenFile | quote }}
}

otelcol.auth.bearer {{ include "helper.alloy_name" .name | quote }} {
  token = local.file.{{ include "helper.alloy_name" .name }}.content
}
{{- else }}

otelcol.auth.bearer {{ include "helper.alloy_name" .name | quote }} {
  token = {{ include "secrets.read" (dict "object" . "key" "auth.bearerToken") }}
}
{{- end }}
{{- else if eq (include "secrets.authType" .) "oauth2" }}

otelcol.auth.oauth2 {{ include "helper.alloy_name" .name | quote }} {
  {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "auth.oauth2.clientId")) "true" }}
  client_id = {{ include "secrets.read" (dict "object" . "key" "auth.oauth2.clientId" "nonsensitive" true) }}
  {{- end }}
  {{- if .auth.oauth2.clientSecretFile }}
  client_secret_file = {{ .auth.oauth2.clientSecretFile | quote }}
  {{- else if eq (include "secrets.usesSecret" (dict "object" . "key" "auth.oauth2.clientSecret")) "true" }}
  client_secret = {{ include "secrets.read" (dict "object" . "key" "auth.oauth2.clientSecret") }}
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
    {{ $k | quote }} = {{ $v | toJson }},
  {{- end }}
  }
  {{- end }}
  {{- if .auth.oauth2.scopes }}
  scopes = {{ .auth.oauth2.scopes | toJson }}
  {{- end }}
  {{- if .auth.oauth2.tokenURL }}
  token_url = {{ .auth.oauth2.tokenURL | quote }}
  {{- end }}
}
{{- else if eq (include "secrets.authType" .) "sigv4" }}

otelcol.auth.sigv4 {{ include "helper.alloy_name" .name | quote }} {
  {{- if .auth.sigv4.region }}
  region = {{ .auth.sigv4.region | quote }}
  {{- end }}
  {{- if .auth.sigv4.service }}
  service = {{ .auth.sigv4.service | quote }}
  {{- end }}
  {{- if (or .auth.sigv4.assumeRole.arn .auth.sigv4.assumeRole.sessionName .auth.sigv4.assumeRole.stsRegion) }}
  assume_role {
    {{- if .auth.sigv4.assumeRole.arn }}
    arn = {{ .auth.sigv4.assumeRole.arn | quote }}
    {{- end }}
    {{- if .auth.sigv4.assumeRole.sessionName }}
    session_name = {{ .auth.sigv4.assumeRole.sessionName | quote }}
    {{- end }}
    {{- if .auth.sigv4.assumeRole.stsRegion }}
    sts_region = {{ .auth.sigv4.assumeRole.stsRegion | quote }}
    {{- end }}
  {{- end }}
}
{{- end }}
{{- end }}
{{- end }}

{{- define "secrets.list.faro" -}}
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

{{/*
{{- define "destinations.faro.alloy.faro.logs.target" }}otelcol.receiver.loki.{{ include "helper.alloy_name" .name }}.receiver{{ end }}
{{- define "destinations.faro.alloy.faro.traces.target" }}otelcol.receiver.loki.{{ include "helper.alloy_name" .name }}.receiver{{ end }}
*/}}
{{- define "destinations.faro.alloy.otlp.target" }}otelcol.processor.attributes.{{ include "helper.alloy_name" .name }}.input{{ end }}
{{- define "destinations.faro.alloy.faro.logs.target" }}{{ include "destinations.faro.alloy.otlp.target" . }}{{- end }}
{{- define "destinations.faro.alloy.faro.traces.target" }}{{ include "destinations.faro.alloy.otlp.target" . }}{{- end }}

{{- define "destinations.faro.supports_metrics" }}false{{ end -}}
{{- define "destinations.faro.supports_logs" }}true{{ end -}}
{{- define "destinations.faro.supports_traces" }}true{{ end -}}
{{- define "destinations.faro.supports_profiles" }}false{{ end -}}
{{- define "destinations.faro.ecosystem" }}faro{{ end -}}
