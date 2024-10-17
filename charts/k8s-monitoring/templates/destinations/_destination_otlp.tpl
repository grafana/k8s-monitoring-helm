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
{{- if eq (include "destinations.auth.type" .) "basic" }}
otelcol.auth.basic {{ include "helper.alloy_name" .name | quote }} {
  username = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.username" "nonsensitive" true) }}
  password = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.password") }}
}
{{- else if eq (include "destinations.auth.type" .) "bearerToken" }}
otelcol.auth.bearer {{ include "helper.alloy_name" .name | quote }} {
  token = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.bearerToken") }}
}
{{- end }}

otelcol.processor.transform {{ include "helper.alloy_name" .name | quote }} {
  error_mode = "ignore"
  metric_statements {
    context = "resource"
    statements = ["set(attributes[\"k8s.cluster.name\"], \"{{ $.clusterName }}\") where attributes[\"k8s.cluster.name\"] == nil"]
  }
  log_statements {
    context = "resource"
    statements = ["set(attributes[\"k8s.cluster.name\"], \"{{ $.clusterName }}\") where attributes[\"k8s.cluster.name\"] == nil"]
  }
  trace_statements {
    context = "resource"
    statements = ["set(attributes[\"k8s.cluster.name\"], \"{{ $.clusterName }}\") where attributes[\"k8s.cluster.name\"] == nil"]
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
{{- if eq .authMode "basic" }}
    auth = otelcol.auth.basic.{{ include "helper.alloy_name" .name }}.handler
{{- else if eq .authMode "bearerToken" }}
    auth = otelcol.auth.bearer.{{ include "helper.alloy_name" .name }}.handler
{{- end }}
    headers = {
{{- if eq (include "destinations.secret.uses_secret" (dict "destination" . "key" "tenantId")) "true" }}
      "X-Scope-OrgID" = {{ include "destinations.secret.read" (dict "destination" . "key" "tenantId" "nonsensitive" true) }},
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
  }
}
{{- end }}
{{- end }}

{{- define "destinations.otlp.secrets" -}}
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
