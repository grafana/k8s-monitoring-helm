{{- define "destinations.loki.alloy" }}
{{- $defaultValues := "destinations/loki-values.yaml" | .Files.Get | fromYaml }}
{{- with merge .destination $defaultValues }}
otelcol.exporter.loki {{ include "helper.alloy_name" .name | quote }} {
  forward_to = [loki.write.{{ include "helper.alloy_name" .name }}.receiver]
}

loki.write {{ include "helper.alloy_name" .name | quote }} {
  endpoint {
    url = {{ .url | quote }}
{{- if eq (include "destinations.secret.uses_secret" (dict "destination" . "key" "tenantId")) "true" }}
    tenant_id = {{ include "destinations.secret.read" (dict "destination" . "key" "tenantId" "nonsensitive" true) }}
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
{{- if eq (include "destinations.auth.type" .) "basic" }}
    basic_auth {
      username = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.username" "nonsensitive" true) }}
      password = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.password") }}
    }
{{- else if eq (include "destinations.auth.type" .) "bearerToken" }}
    bearer_token = {{ include "destinations.secret.read" (dict "destination" . "key" "auth.bearerToken") }}
{{- end }}
  }
  external_labels = {
    cluster = {{ $.clusterName | quote }},
    "k8s_cluster_name" = {{ $.clusterName | quote }},
{{- if .externalLabels }}
  {{- range $k, $v := .externalLabels }}
    {{ $k }} = {{ $v | quote }},
  {{- end }}
{{- end }}
{{- if .externalLabelsFrom }}
  {{- range $k, $v := .externalLabelsFrom }}
    {{ $k }} = {{ $v }},
  {{- end }}
{{- end }}
  }
}
{{- end }}
{{- end }}

{{- define "destinations.loki.secrets" -}}
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
