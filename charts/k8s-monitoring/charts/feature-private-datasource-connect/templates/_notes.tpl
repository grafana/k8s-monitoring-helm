{{- define "feature.privateDatasourceConnect.notes.deployments" }}{{- end }}

{{- define "feature.privateDatasourceConnect.notes.task" }}
Enable secure connectivity between Grafana Cloud and private data sources using the PDC agent
{{- end }}

{{- define "feature.privateDatasourceConnect.notes.actions" }}
* Private Data Source Connect agent is deployed and will establish secure tunnels to Grafana Cloud
* Configure your Grafana Cloud data sources to use the PDC connection for accessing private resources
{{- end }}

{{- define "feature.privateDatasourceConnect.summary" -}}
version: {{ .Chart.Version }}
{{- end }} 