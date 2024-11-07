{{- define "destinations.loki.alloy" }}
{{- $defaultValues := "destinations/loki-values.yaml" | .Files.Get | fromYaml }}
{{- with merge .destination $defaultValues }}
otelcol.exporter.loki {{ include "helper.alloy_name" .name | quote }} {
  forward_to = [loki.write.{{ include "helper.alloy_name" .name }}.receiver]
}

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
{{- if eq (include "secrets.authType" .) "basic" }}
    basic_auth {
      username = {{ include "secrets.read" (dict "object" . "key" "auth.username" "nonsensitive" true) }}
      password = {{ include "secrets.read" (dict "object" . "key" "auth.password") }}
    }
{{- else if eq (include "secrets.authType" .) "bearerToken" }}
    bearer_token = {{ include "secrets.read" (dict "object" . "key" "auth.bearerToken") }}
{{- end }}
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
{{- end -}}

{{- define "destinations.loki.alloy.loki.logs.target" }}loki.write.{{ include "helper.alloy_name" .name }}.receiver{{ end -}}
{{- define "destinations.loki.alloy.otlp.logs.target" }}otelcol.exporter.loki.{{ include "helper.alloy_name" .name }}.input{{ end -}}

{{- define "destinations.loki.supports_metrics" }}false{{ end -}}
{{- define "destinations.loki.supports_logs" }}true{{ end -}}
{{- define "destinations.loki.supports_traces" }}false{{ end -}}
{{- define "destinations.loki.supports_profiles" }}false{{ end -}}
{{- define "destinations.loki.ecosystem" }}loki{{ end -}}
