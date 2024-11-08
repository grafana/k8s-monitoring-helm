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
otelcol.auth.bearer {{ include "helper.alloy_name" .name | quote }} {
  token = {{ include "secrets.read" (dict "object" . "key" "auth.bearerToken") }}
}
{{- end }}

otelcol.processor.transform {{ include "helper.alloy_name" .name | quote }} {
  error_mode = "ignore"
  metric_statements {
    context = "resource"
    statements = ["set(attributes[\"cluster\"], \"{{ $.Values.cluster.name }}\") where attributes[\"cluster\"] == nil"]
    statements = ["set(attributes[\"k8s.cluster.name\"], \"{{ $.Values.cluster.name }}\") where attributes[\"k8s.cluster.name\"] == nil"]
  }
  log_statements {
    context = "resource"
    statements = ["set(attributes[\"cluster\"], \"{{ $.Values.cluster.name }}\") where attributes[\"cluster\"] == nil"]
    statements = ["set(attributes[\"k8s.cluster.name\"], \"{{ $.Values.cluster.name }}\") where attributes[\"k8s.cluster.name\"] == nil"]
  }
  trace_statements {
    context = "resource"
    statements = ["set(attributes[\"cluster\"], \"{{ $.Values.cluster.name }}\") where attributes[\"cluster\"] == nil"]
    statements = ["set(attributes[\"k8s.cluster.name\"], \"{{ $.Values.cluster.name }}\") where attributes[\"k8s.cluster.name\"] == nil"]
  }

  output {
{{- $target := "" }}
{{- if eq .protocol "grpc" }}
{{- $target = printf "otelcol.exporter.otlp.%s.input" (include "helper.alloy_name" .name) }}
{{- else if eq .protocol "http" }}
{{- $target = printf "otelcol.exporter.otlphttp.%s.input" (include "helper.alloy_name" .name) }}
{{- end }}
    metrics = [{{ $target }}]
    logs = [{{ $target }}]
    traces = [{{ $target }}]
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
}
{{- end }}
{{- end }}

{{- define "secrets.list.otlp" -}}
- tenantId
- auth.username
- auth.password
- auth.bearerToken
- tls.ca
- tls.cert
- tls.key
{{- end -}}

{{- define "destinations.otlp.alloy.prometheus.metrics.target" }}otelcol.receiver.prometheus.{{ include "helper.alloy_name" .name }}.receiver{{ end }}
{{- define "destinations.otlp.alloy.loki.logs.target" }}otelcol.receiver.loki.{{ include "helper.alloy_name" .name }}.receiver{{ end }}
{{- define "destinations.otlp.alloy.otlp.target" }}otelcol.processor.transform.{{ include "helper.alloy_name" .name }}.input{{ end }}
{{- define "destinations.otlp.alloy.otlp.metrics.target" }}{{ include "destinations.otlp.alloy.otlp.target" . }}{{- end }}
{{- define "destinations.otlp.alloy.otlp.logs.target" }}{{ include "destinations.otlp.alloy.otlp.target" . }}{{- end }}
{{- define "destinations.otlp.alloy.otlp.traces.target" }}{{ include "destinations.otlp.alloy.otlp.target" . }}{{- end }}

{{- define "destinations.otlp.supports_metrics" }}{{ dig "metrics" "enabled" "false" . }}{{ end -}}
{{- define "destinations.otlp.supports_logs" }}{{ dig "logs" "enabled" "false" . }}{{ end -}}
{{- define "destinations.otlp.supports_traces" }}{{ dig "traces" "enabled" "true" . }}{{ end -}}
{{- define "destinations.otlp.supports_profiles" }}false{{ end -}}
{{- define "destinations.otlp.ecosystem" }}otlp{{ end -}}
