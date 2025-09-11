{{- define "feature.privateDatasourceConnect.validate" -}}
{{- if .Values.enabled }}
  {{- if not (index .Values "pdc-agent") }}
    {{- $msg := list "" "PDC Agent is enabled but no pdc-agent configuration is provided. Please provide configuration in the 'pdc-agent' section. For example:" }}
    {{- $msg = append $msg "pdc-agent:" }}
    {{- $msg = append $msg "  cluster: \"prod-us-central-0\"" }}
    {{- $msg = append $msg "  hostedGrafanaId: \"123456\"" }}
    {{- $msg = append $msg "  tokenSecretName: \"pdc-token\"" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- if not (index .Values "pdc-agent" "cluster") }}
    {{- $msg := list "" "PDC Agent is enabled but no cluster is specified. Please specify the cluster where your Hosted Grafana stack is running. For example:" }}
    {{- $msg = append $msg "pdc-agent:" }}
    {{- $msg = append $msg "  cluster: \"prod-us-central-0\"" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- if not (index .Values "pdc-agent" "hostedGrafanaId") }}
    {{- $msg := list "" "PDC Agent is enabled but no hostedGrafanaId is specified. Please specify the numeric ID of your Hosted Grafana stack. For example:" }}
    {{- $msg = append $msg "pdc-agent:" }}
    {{- $msg = append $msg "  hostedGrafanaId: \"123456\"" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- if and (not (index .Values "pdc-agent" "tokenSecretName")) (not (index .Values "pdc-agent" "insecureTokenValue")) }}
    {{- $msg := list "" "PDC Agent is enabled but no authentication token is provided. Please specify either tokenSecretName or insecureTokenValue. For example:" }}
    {{- $msg = append $msg "pdc-agent:" }}
    {{- $msg = append $msg "  tokenSecretName: \"pdc-token\"" }}
    {{- $msg = append $msg "  # OR for testing only:" }}
    {{- $msg = append $msg "  # insecureTokenValue: \"your-token-here\"" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- if and .Values.scrapeInterval (not (regexMatch "^[0-9]+(ns|us|µs|ms|s|m|h)$" .Values.scrapeInterval)) }}
    {{- fail "PDC Agent scrapeInterval must be a valid duration (e.g., '30s', '1m', '5m')" }}
  {{- end }}

  {{- if and .Values.scrapeTimeout (not (regexMatch "^[0-9]+(ns|us|µs|ms|s|m|h)$" .Values.scrapeTimeout)) }}
    {{- fail "PDC Agent scrapeTimeout must be a valid duration (e.g., '10s', '30s')" }}
  {{- end }}

  {{- if and .Values.maxCacheSize (not (kindIs "float64" .Values.maxCacheSize)) }}
    {{- fail "PDC Agent maxCacheSize must be a number" }}
  {{- end }}
{{- end }}
{{- end }}
