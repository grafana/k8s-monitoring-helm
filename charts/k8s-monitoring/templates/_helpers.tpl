{{ define "prometheus-relabel" }}
forward_to = [prometheus.remote_write.grafana_cloud_prometheus.receiver]
{{- if .allowList }}
rule {
  source_labels = ["__name__"]
  regex = "up|{{ join "|" (index .Values .Name).allowList }}"
  action = "keep"
}
{{- end }}
{{- (index .Values .Name).additionalMetricRelabelingRules }}
{{- end }}

{{ define "prometheus-collect" }}
job_name   = "integrations/{{ .Name }}"
targets  = discovery.relabel.{{ .Name }}.output
forward_to = [prometheus.relabel.{{ .Name }}.receiver]
{{- with (index .Values .Name).scrape_interval }}
scrape_interval = {{ . | quote }}
{{- end }}
{{- end }}
