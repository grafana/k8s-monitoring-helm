{{- define "feature.privateDatasourceConnect.notes.deployments" }}
{{- if .Values.enabled }}
* PDC Agent deployment and associated resources
{{- end }}
{{- end }}

{{- define "feature.privateDatasourceConnect.notes.task" }}
{{- if .Values.enabled }}
Deploys and monitors the PDC (Private Data Cloud) Agent for Grafana Cloud observability.
{{- else }}
PDC Agent feature is disabled.
{{- end }}
{{- end }}

{{- define "feature.privateDatasourceConnect.notes.actions" }}
{{- if .Values.enabled }}
{{- if not (index .Values "pdc-agent" "image" "tag") }}
NOTE: No specific image tag was set for PDC Agent. The chart will use the default tag.
{{- end }}
{{- if not (index .Values "pdc-agent" "cluster") }}
WARNING: PDC Agent cluster is not configured. Please set 'pdc-agent.cluster'.
{{- end }}
{{- if not (index .Values "pdc-agent" "hostedGrafanaId") }}
WARNING: PDC Agent hostedGrafanaId is not configured. Please set 'pdc-agent.hostedGrafanaId'.
{{- end }}
{{- if and (not (index .Values "pdc-agent" "tokenSecretName")) (not (index .Values "pdc-agent" "insecureTokenValue")) }}
WARNING: PDC Agent authentication token is not configured. Please set either 'tokenSecretName' or 'insecureTokenValue'.
{{- end }}
{{- if index .Values "pdc-agent" "debug" }}
NOTE: PDC Agent debug logging is enabled. This may produce verbose logs.
{{- end }}
{{- end }}
{{- end }}

{{- define "feature.privateDatasourceConnect.summary" -}}
version: {{ .Chart.Version }}
enabled: {{ .Values.enabled }}
{{- if .Values.enabled }}
{{- if .Values.namespace }}
namespace: {{ .Values.namespace }}
{{- end }}
{{- if .Values.scrapeInterval }}
scrapeInterval: {{ .Values.scrapeInterval }}
{{- else if .Values.global.scrapeInterval }}
scrapeInterval: {{ .Values.global.scrapeInterval }}
{{- end }}
metricsPort: {{ index .Values "pdc-agent" "metricsPort" | default "8090" }}
{{- if index .Values "pdc-agent" "replicaCount" }}
replicas: {{ index .Values "pdc-agent" "replicaCount" }}
{{- end }}
{{- if index .Values "pdc-agent" "cluster" }}
cluster: {{ index .Values "pdc-agent" "cluster" }}
{{- end }}
{{- if index .Values "pdc-agent" "hostedGrafanaId" }}
hostedGrafanaId: {{ index .Values "pdc-agent" "hostedGrafanaId" }}
{{- end }}
{{- end }}
{{- end }}
