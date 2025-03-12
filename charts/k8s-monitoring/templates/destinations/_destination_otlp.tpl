{{- define "destinations.otlp.alloy" }}
{{- $defaultValues := "destinations/otlp-values.yaml" | .Files.Get | fromYaml }}
{{- with merge .destination $defaultValues }}
{{- if eq (include "destinations.otlp.supports_metrics" .) "true" }}
otelcol.receiver.prometheus {{ include "helper.alloy_name" .name | quote }} {
  output {
    metrics = [{{ include "destinations.otlp.alloy.otlp.metrics.target" . | trim }}]
  }
}
{{- end }}
{{- if eq (include "destinations.otlp.supports_logs" .) "true" }}
otelcol.receiver.loki {{ include "helper.alloy_name" .name | quote }} {
  output {
    logs = [{{ include "destinations.otlp.alloy.otlp.logs.target" . | trim }}]
  }
}
{{- end }}
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
  {{- if .auth.oauth2.scopes }}
  scopes = {{ .auth.oauth2.scopes | toJson }}
  {{- end }}
  {{- if .auth.oauth2.tokenURL }}
  token_url = {{ .auth.oauth2.tokenURL | quote }}
  {{- end }}
}
{{- end }}

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
    metrics = [otelcol.processor.transform.{{ include "helper.alloy_name" .name }}.input]
    logs = [otelcol.processor.transform.{{ include "helper.alloy_name" .name }}.input]
    traces = [otelcol.processor.transform.{{ include "helper.alloy_name" .name }}.input]
  }
}

otelcol.processor.transform {{ include "helper.alloy_name" .name | quote }} {
  error_mode = "ignore"
{{- if ne .metrics.enabled false }}
  metric_statements {
    context = "resource"
    statements = [
      `set(attributes["cluster"], {{ $.Values.cluster.name | quote }})`,
      `set(attributes["k8s.cluster.name"], {{ $.Values.cluster.name | quote }})`,
{{- if .processors.transform.metrics.resource }}
{{- range $transform := .processors.transform.metrics.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- end }}
    ]
  }

{{- if .processors.transform.metrics.metric }}
  metric_statements {
    context = "metric"
    statements = [

{{- range $transform := .processors.transform.metrics.metric }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}

  metric_statements {
    context = "datapoint"
    statements = [
      `set(attributes["cluster"], {{ $.Values.cluster.name | quote }})`,
      `set(attributes["k8s.cluster.name"], {{ $.Values.cluster.name | quote }})`,
{{- if .processors.transform.metrics.datapoint }}
{{- range $transform := .processors.transform.metrics.datapoint }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- end }}
    ]
  }

{{- end }}
{{- if ne .logs.enabled false }}
  log_statements {
    context = "resource"
    statements = [
      `set(attributes["cluster"], {{ $.Values.cluster.name | quote }})`,
      `set(attributes["k8s.cluster.name"], {{ $.Values.cluster.name | quote }})`,
{{- if .processors.transform.logs.resource }}
{{- range $transform := .processors.transform.logs.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- end }}
    ]
  }

  log_statements {
    context = "log"
    statements = [
      `delete_key(attributes, "loki.attribute.labels")`,
      `delete_key(attributes, "loki.resource.labels")`,
      `set(resource.attributes["service.name"], attributes["service_name"]) where resource.attributes["service.name"] == nil and attributes["service_name"] != nil`,
      `delete_key(attributes, "service_name") where attributes["service_name"] != nil`,
      `set(resource.attributes["service.namespace"], attributes["service_namespace"] ) where resource.attributes["service.namespace"] == nil and attributes["service_namespace"] != nil`,
      `delete_key(attributes, "service_namespace") where attributes["service_namespace"] != nil`,
      `set(resource.attributes["deployment.environment.name"], attributes["deployment_environment_name"] ) where resource.attributes["deployment.environment.name"] == nil and attributes["deployment_environment_name"] != nil`,
      `delete_key(attributes, "deployment_environment_name") where attributes["deployment_environment_name"] != nil`,
      `set(resource.attributes["deployment.environment"], attributes["deployment_environment"] ) where resource.attributes["deployment.environment"] == nil and attributes["deployment_environment"] != nil`,
      `delete_key(attributes, "deployment_environment") where attributes["deployment_environment"] != nil`,
{{- if .processors.transform.logs.log }}
{{- range $transform := .processors.transform.logs.log }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- end }}
    ]
  }
{{- if .processors.transform.logs.scope }}
  log_statements {
    context = "scope"
    statements = [
{{- range $transform := .processors.transform.logs.scope }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- end }}
{{- if ne .traces.enabled false }}

  trace_statements {
    context = "resource"
    statements = [
      `set(attributes["cluster"], {{ $.Values.cluster.name | quote }})`,
      `set(attributes["k8s.cluster.name"], {{ $.Values.cluster.name | quote }})`,
{{- if .processors.transform.traces.resource }}
{{- range $transform := .processors.transform.traces.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- end }}
    ]
  }
{{- if .processors.transform.traces.span }}
  trace_statements {
    context = "span"
    statements = [
{{- range $transform := .processors.transform.traces.span }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if .processors.transform.traces.spanevent }}
  trace_statements {
    context = "spanevent"
    statements = [
{{- range $transform := .processors.transform.traces.spanevent }}
{{ $transform | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- end }}
{{- if .processors.filters.enabled }}

  output {
{{- if ne .metrics.enabled false }}
    metrics = [otelcol.processor.filter.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
{{- if ne .logs.enabled false }}
    logs = [otelcol.processor.filter.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
{{- if ne .traces.enabled false }}
    traces = [otelcol.processor.filter.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
  }
}

otelcol.processor.filter {{ include "helper.alloy_name" .name | quote }} {
{{- if and .metrics.enabled (or .processors.filters.metrics.metric .processors.filters.metrics.datapoint) }}
  metrics {
{{- if .processors.filters.metrics.metric }}
    metric = [
{{- range $filter := .processors.filters.metrics.metric }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
{{- end }}
{{- if .processors.filters.metrics.datapoint }}
    datapoint = [
{{- range $filter := .processors.filters.metrics.datapoint }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
{{- end }}
  }
{{- end }}
{{- if and .logs.enabled .processors.filters.logs.log_record }}
  logs {
    log_record = [
{{- range $filter := .processors.filters.logs.log_record }}
{{ $filter | quote | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if and .traces.enabled (or .processors.filters.traces.span .processors.filters.traces.spanevent) }}
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
{{- if .processors.batch.enabled }}

  output {
{{- if ne .metrics.enabled false }}
    metrics = [otelcol.processor.batch.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
{{- if ne .logs.enabled false }}
    logs = [otelcol.processor.batch.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
{{- if ne .traces.enabled false }}
    traces = [otelcol.processor.batch.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
  }
}

otelcol.processor.batch {{ include "helper.alloy_name" .name | quote }} {
  timeout = {{ .processors.batch.timeout | quote }}
  send_batch_size = {{ .processors.batch.size | int }}
  send_batch_max_size = {{ .processors.batch.maxSize | int }}
{{- end }}
{{- if .processors.memoryLimiter.enabled }}

  output {
{{- if ne .metrics.enabled false }}
    metrics = [otelcol.processor.memory_limiter.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
{{- if ne .logs.enabled false }}
    logs = [otelcol.processor.memory_limiter.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
{{- if ne .traces.enabled false }}
    traces = [otelcol.processor.memory_limiter.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
  }
}

otelcol.processor.memory_limiter {{ include "helper.alloy_name" .name | quote }} {
  check_interval = {{ .processors.memoryLimiter.checkInterval | quote }}
  limit = {{ .processors.memoryLimiter.limit | quote }}
{{- end }}

  output {
{{- $target := "" }}
{{- if eq .protocol "grpc" }}
{{- $target = printf "otelcol.exporter.otlp.%s.input" (include "helper.alloy_name" .name) }}
{{- else if eq .protocol "http" }}
{{- $target = printf "otelcol.exporter.otlphttp.%s.input" (include "helper.alloy_name" .name) }}
{{- end }}
{{- if ne .metrics.enabled false }}
    metrics = [{{ $target }}]
{{- end }}
{{- if ne .logs.enabled false }}
    logs = [{{ $target }}]
{{- end }}
{{- if ne .traces.enabled false }}
    traces = [{{ $target }}]
{{- end }}
  }
}

{{- if eq .protocol "grpc" }}
otelcol.exporter.otlp {{ include "helper.alloy_name" .name | quote }} {
{{- else if eq .protocol "http" }}
otelcol.exporter.otlphttp {{ include "helper.alloy_name" .name | quote }} {
{{- end }}
  client {
{{- if .urlFrom }}
    endpoint = {{ .urlFrom }}
{{- else }}
    endpoint = {{ .url | quote }}
{{- end }}
{{- if eq .auth.type "basic" }}
    auth = otelcol.auth.basic.{{ include "helper.alloy_name" .name }}.handler
{{- else if eq .auth.type "bearerToken" }}
    auth = otelcol.auth.bearer.{{ include "helper.alloy_name" .name }}.handler
{{- else if eq .auth.type "oauth2" }}
    auth = otelcol.auth.oauth2.{{ include "helper.alloy_name" .name }}.handler
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
    enabled = {{ .retryOnFailure.enabled | default true }}
    initial_interval = {{ .retryOnFailure.initialInterval | quote }}
    max_interval = {{ .retryOnFailure.maxInterval | quote }}
    max_elapsed_time = {{ .retryOnFailure.maxElapsedTime | quote }}
  }
}
{{- end }}
{{- end }}

{{- define "secrets.list.otlp" -}}
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

{{- define "destinations.otlp.alloy.prometheus.metrics.target" }}otelcol.receiver.prometheus.{{ include "helper.alloy_name" .name }}.receiver{{ end }}
{{- define "destinations.otlp.alloy.loki.logs.target" }}otelcol.receiver.loki.{{ include "helper.alloy_name" .name }}.receiver{{ end }}
{{- define "destinations.otlp.alloy.otlp.target" }}otelcol.processor.attributes.{{ include "helper.alloy_name" .name }}.input{{ end }}
{{- define "destinations.otlp.alloy.otlp.metrics.target" }}{{ include "destinations.otlp.alloy.otlp.target" . }}{{- end }}
{{- define "destinations.otlp.alloy.otlp.logs.target" }}{{ include "destinations.otlp.alloy.otlp.target" . }}{{- end }}
{{- define "destinations.otlp.alloy.otlp.traces.target" }}{{ include "destinations.otlp.alloy.otlp.target" . }}{{- end }}

{{- define "destinations.otlp.supports_metrics" }}{{ dig "metrics" "enabled" "false" . }}{{ end -}}
{{- define "destinations.otlp.supports_logs" }}{{ dig "logs" "enabled" "false" . }}{{ end -}}
{{- define "destinations.otlp.supports_traces" }}{{ dig "traces" "enabled" "true" . }}{{ end -}}
{{- define "destinations.otlp.supports_profiles" }}false{{ end -}}
{{- define "destinations.otlp.ecosystem" }}otlp{{ end -}}
