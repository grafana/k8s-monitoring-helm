{{- define "features.privateDatasourceConnect.enabled" }}{{ .Values.privateDatasourceConnect.enabled }}{{- end }}

{{- define "features.privateDatasourceConnect.collectors" }}
{{- if .Values.privateDatasourceConnect.enabled -}}
{{/* PDC doesn't use collectors, it's a standalone agent */}}
{{- end }}
{{- end }}

{{- define "features.privateDatasourceConnect.include" }}
{{- if .Values.privateDatasourceConnect.enabled -}}
{{/* PDC agent runs as a standalone deployment, no Alloy config needed */}}
{{- end -}}
{{- end -}}

{{- define "features.privateDatasourceConnect.destinations" }}
{{- if .Values.privateDatasourceConnect.enabled -}}
- "Grafana Cloud"
{{- end -}}
{{- end -}}

{{- define "features.privateDatasourceConnect.destinations.isTranslating" }}
false
{{- end -}}

{{- define "features.privateDatasourceConnect.collector.values" }}{{- end -}}

{{- define "features.privateDatasourceConnect.validate" }}
{{- if .Values.privateDatasourceConnect.enabled -}}
{{- $featureName := "Private Data Source Connect" }}
{{/* Validate PDC credentials are provided */}}
{{- $pdcValues := .Values.privateDatasourceConnect }}
{{- if $pdcValues.credentials.createSecret }}
  {{- if not $pdcValues.credentials.token }}
    {{- fail "Private Data Source Connect: credentials.token is required when credentials.createSecret is true" }}
  {{- end }}
  {{- if not $pdcValues.credentials.hostedGrafanaId }}
    {{- fail "Private Data Source Connect: credentials.hostedGrafanaId is required when credentials.createSecret is true" }}
  {{- end }}
  {{- if not $pdcValues.credentials.cluster }}
    {{- fail "Private Data Source Connect: credentials.cluster is required when credentials.createSecret is true" }}
  {{- end }}
{{- else }}
  {{- if not $pdcValues.credentials.existingSecret }}
    {{- fail "Private Data Source Connect: credentials.existingSecret is required when credentials.createSecret is false" }}
  {{- end }}
{{- end }}
{{- end -}}
{{- end -}} 