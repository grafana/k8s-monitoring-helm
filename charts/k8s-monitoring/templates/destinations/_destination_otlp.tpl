{{ define "destinations.otlp.resourceAttributes.removeList" }}
{{- $destination := .destination }}
{{- $root := .root }}
{{- $removeList := list }}
{{ if $destination.processors.resourceAttributes.useDefaultRemoveList }}
{{- $removeList = ($root.Files.Get "default-remove-lists/resource-attributes.yaml" | fromYamlArray) -}}
{{ end }}
{{ if $destination.processors.resourceAttributes.removeList }}
{{- $removeList = concat $removeList $destination.processors.resourceAttributes.removeList -}}
{{ end }}
{{ $removeList | uniq | toYaml }}
{{ end }}

{{- define "destinations.otlp.alloy" }}
{{- with .destination }}
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
{{- if ne .metrics.enabled false }}
    metrics = [otelcol.processor.transform.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
{{- if ne .logs.enabled false }}
    logs = [otelcol.processor.transform.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
{{- if ne .traces.enabled false }}
    traces = [otelcol.processor.transform.{{ include "helper.alloy_name" .name }}.input]
{{- end }}
  }
}

otelcol.processor.transform {{ include "helper.alloy_name" .name | quote }} {
  error_mode = {{ .processors.transform.errorMode | quote }}

{{- if ne .metrics.enabled false }}
{{- $resourceAttributesToRemove := include "destinations.otlp.resourceAttributes.removeList" (dict "destination" . "root" $) | fromYamlArray }}
  metric_statements {
    context = "resource"
    statements = [
{{- range $label := .clusterLabels }}
      `set(attributes[{{ $label | quote }}], {{ $.Values.cluster.name | quote }})`,
{{- end }}
{{- range $resourceAttribute := $resourceAttributesToRemove }}
      `delete_key(attributes, {{ $resourceAttribute | quote }})`,
{{- end }}
{{- range $transform := .processors.transform.metrics.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- range $transform := .processors.transform.metrics.resourceFrom }}
{{ $transform | indent 6 }},
{{- end }}
    ]
  }

{{- if or .processors.transform.metrics.metric .processors.transform.metrics.metricFrom }}
  metric_statements {
    context = "metric"
    statements = [
{{- range $transform := .processors.transform.metrics.metric }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- range $transform := .processors.transform.metrics.metricFrom }}
{{ $transform | indent 6 }},
{{- end }}
    ]
  }
{{- end }}

  metric_statements {
    context = "datapoint"
    statements = [
{{- range $label := .clusterLabels }}
      `set(attributes[{{ $label | quote }}], {{ $.Values.cluster.name | quote }})`,
{{- end }}
{{- range $datapointAttribute, $resourceAttribute := .processors.transform.metrics.datapointToResource }}
  {{- if $resourceAttribute }}
      `set(resource.attributes[{{ $resourceAttribute | quote }}], attributes[{{ $datapointAttribute | quote }}] ) where resource.attributes[{{ $resourceAttribute | quote }}] == nil and attributes[{{ $datapointAttribute | quote }}] != nil`,
      `delete_key(attributes, {{ $datapointAttribute | quote }}) where attributes[{{ $datapointAttribute | quote }}] == resource.attributes[{{ $resourceAttribute | quote }}]`,
  {{- end }}
{{- end }}
{{- range $transform := .processors.transform.metrics.datapoint }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- range $transform := .processors.transform.metrics.datapointFrom }}
{{ $transform | indent 6 }},
{{- end }}
    ]
  }

{{- end }}
{{- if ne .logs.enabled false }}
{{- $resourceAttributesToRemove := include "destinations.otlp.resourceAttributes.removeList" (dict "destination" . "root" $) | fromYamlArray }}
  log_statements {
    context = "resource"
    statements = [
{{- range $label := .clusterLabels }}
      `set(attributes[{{ $label | quote }}], {{ $.Values.cluster.name | quote }})`,
{{- end }}
{{- range $resourceAttribute := $resourceAttributesToRemove }}
      `delete_key(attributes, {{ $resourceAttribute | quote }})`,
{{- end }}
{{- range $transform := .processors.transform.logs.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- range $transform := .processors.transform.logs.resourceFrom }}
{{ $transform | indent 6 }},
{{- end }}
    ]
  }

  log_statements {
    context = "log"
    statements = [
      `delete_key(attributes, "loki.attribute.labels")`,
      `delete_key(attributes, "loki.resource.labels")`,
{{- range $logAttribute, $resourceAttribute := .processors.transform.logs.logToResource }}
  {{- if $resourceAttribute }}
      `set(resource.attributes[{{ $resourceAttribute | quote }}], attributes[{{ $logAttribute | quote }}] ) where resource.attributes[{{ $resourceAttribute | quote }}] == nil and attributes[{{ $logAttribute | quote }}] != nil`,
      `delete_key(attributes, {{ $logAttribute | quote }}) where attributes[{{ $logAttribute | quote }}] == resource.attributes[{{ $resourceAttribute | quote }}]`,
  {{- end }}
{{- end }}
{{- range $transform := .processors.transform.logs.log }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- range $transform := .processors.transform.logs.logFrom }}
{{ $transform | indent 6 }},
{{- end }}
    ]
  }
{{- if or .processors.transform.logs.scope .processors.transform.logs.scopeFrom }}
  log_statements {
    context = "scope"
    statements = [
{{- range $transform := .processors.transform.logs.scope }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- range $transform := .processors.transform.logs.scopeFrom }}
{{ $transform | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- end }}
{{- if ne .traces.enabled false }}
{{- $resourceAttributesToRemove := include "destinations.otlp.resourceAttributes.removeList" (dict "destination" . "root" $) | fromYamlArray }}

  trace_statements {
    context = "resource"
    statements = [
{{- range $label := .clusterLabels }}
      `set(attributes[{{ $label | quote }}], {{ $.Values.cluster.name | quote }})`,
{{- end }}
{{- range $resourceAttribute := $resourceAttributesToRemove }}
      `delete_key(attributes, {{ $resourceAttribute | quote }})`,
{{- end }}
{{- range $transform := .processors.transform.traces.resource }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- range $transform := .processors.transform.traces.resourceFrom }}
{{ $transform | indent 6 }},
{{- end }}
    ]
  }
{{- if or .processors.transform.traces.span .processors.transform.traces.spanFrom }}
  trace_statements {
    context = "span"
    statements = [
{{- range $transform := .processors.transform.traces.span }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- range $transform := .processors.transform.traces.spanFrom }}
{{ $transform | indent 6 }},
{{- end }}
    ]
  }
{{- end }}
{{- if or .processors.transform.traces.spanevent .processors.transform.traces.spaneventFrom }}
  trace_statements {
    context = "spanevent"
    statements = [
{{- range $transform := .processors.transform.traces.spanevent }}
{{ $transform | quote | indent 6 }},
{{- end }}
{{- range $transform := .processors.transform.traces.spaneventFrom }}
{{ $transform | indent 6 }},
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
  error_mode = {{ .processors.filters.errorMode | quote }}

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
{{- if and .logs.enabled .processors.filters.logs.logRecord }}
  logs {
    log_record = [
{{- range $filter := .processors.filters.logs.logRecord }}
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

  output {
{{- if ne .metrics.enabled false }}
    metrics = [{{ include "destinations.otlp.alloy.exporter.target" . }}]
{{- end }}
{{- if ne .logs.enabled false }}
    logs = [{{ include "destinations.otlp.alloy.exporter.target" . }}]
{{- end }}
{{- if ne .traces.enabled false }}
{{- /* If sampling is enabled, override traces target and enable loadbalancing exporter if sampling is enabled */}}
{{- if and .processors.tailSampling.enabled .processors.serviceGraphMetrics.enabled }}
    traces = [
      otelcol.exporter.loadbalancing.{{ printf "%s_sampler" (include "helper.alloy_name" .name) }}.input,
      otelcol.exporter.loadbalancing.{{ printf "%s_servicegraph" (include "helper.alloy_name" .name) }}.input,
    ]
{{- else if .processors.tailSampling.enabled }}
    traces = [otelcol.exporter.loadbalancing.{{ printf "%s_sampler" (include "helper.alloy_name" .name) }}.input]
{{- else if .processors.serviceGraphMetrics.enabled }}
    traces = [
      otelcol.exporter.loadbalancing.{{ printf "%s_servicegraph" (include "helper.alloy_name" .name) }}.input,
      {{ include "destinations.otlp.alloy.exporter.target" . }},
    ]
{{- else }}
    traces = [{{ include "destinations.otlp.alloy.exporter.target" . }}]
{{- end }}
{{- end }}
  }
}

{{- if .processors.tailSampling.enabled }}

otelcol.exporter.loadbalancing {{ printf "%s_sampler" (include "helper.alloy_name" .name) | quote }} {
  resolver {
    kubernetes {
      {{- $maxLength := 51 }}{{/* This limit is from the `controller-revision-hash` pod label value*/}}
      {{- $collectorName := printf "%s-%s" $.Release.Name (include "helper.k8s_name" (printf "%s-sampler" .name)) | trunc $maxLength | trimSuffix "-" | lower }}
      service = "{{ $collectorName }}"
    }
  }
  protocol {
    otlp {
      client {
        tls {
          insecure = true
        }
      }
    }
  }
}
{{- end }}

{{- if .processors.serviceGraphMetrics.enabled }}

otelcol.exporter.loadbalancing {{ printf "%s_servicegraph" (include "helper.alloy_name" .name) | quote }} {
  resolver {
    kubernetes {
      {{- $maxLength := 51 }}{{/* This limit is from the `controller-revision-hash` pod label value*/}}
      {{- $collectorName := printf "%s-%s" $.Release.Name (include "helper.k8s_name" (printf "%s-servicegraph" .name)) | trunc $maxLength | trimSuffix "-" | lower }}
      service = "{{ $collectorName }}"
    }
  }
  protocol {
    otlp {
      client {
        tls {
          insecure = true
        }
      }
    }
  }
}
{{- end }}
{{ include "destinations.otlp.alloy.exporter" . }}
{{- end }}
{{- end }}

{{- define "destinations.otlp.alloy.exporter.target" }}
{{- if .processors.batch.enabled -}}
otelcol.processor.batch.{{ include "helper.alloy_name" .name }}.input
{{- else if .processors.memoryLimiter.enabled -}}
otelcol.processor.memory_limiter.{{ include "helper.alloy_name" .name }}.input
{{- else if eq .protocol "grpc" -}}
otelcol.exporter.otlp.{{ include "helper.alloy_name" .name }}.input
{{- else if eq .protocol "http" -}}
otelcol.exporter.otlphttp.{{ include "helper.alloy_name" .name }}.input
{{- end }}
{{- end }}

{{- define "destinations.otlp.alloy.exporter" }}
{{- if .processors.batch.enabled }}
otelcol.processor.batch {{ include "helper.alloy_name" .name | quote }} {
  timeout = {{ .processors.batch.timeout | quote }}
  send_batch_size = {{ .processors.batch.size | int }}
  send_batch_max_size = {{ .processors.batch.maxSize | int }}
{{- end }}

  output {
{{- $target := "" }}
{{- if .processors.memoryLimiter.enabled }}
  {{- $target = printf "otelcol.processor.memory_limiter.%s.input" (include "helper.alloy_name" .name) }}
{{- else if eq .protocol "grpc" }}
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
{{- if .processors.memoryLimiter.enabled }}

otelcol.processor.memory_limiter {{ include "helper.alloy_name" .name | quote }} {
  check_interval = {{ .processors.memoryLimiter.checkInterval | quote }}
  limit = {{ .processors.memoryLimiter.limit | quote }}

  output {
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
{{- end }}

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
  }
  {{- end }}
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

{{- define "destinations.otlp.supports_metrics" }}{{ dig "metrics" "enabled" "true" . }}{{ end -}}
{{- define "destinations.otlp.supports_logs" }}{{ dig "logs" "enabled" "true" . }}{{ end -}}
{{- define "destinations.otlp.supports_traces" }}{{ dig "traces" "enabled" "true" . }}{{ end -}}
{{- define "destinations.otlp.supports_profiles" }}false{{ end -}}
{{- define "destinations.otlp.ecosystem" }}otlp{{ end -}}

{{- define "destinations.otlp.isTailSamplingEnabled" }}
{{- dig "processors" "tailSampling" "enabled" "false" . -}}
{{- end -}}

{{- define "destinations.otlp.isServiceGraphsEnabled" }}
{{- dig "processors" "serviceGraphMetrics" "enabled" "false" . -}}
{{- end -}}
