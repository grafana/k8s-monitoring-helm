{{ define "prometheus-relabel" -}}
{{- if (index .Values .Name).allowList -}}
rule {
  source_labels = ["__name__"]
  regex = "up|{{ join "|" (index .Values .Name).allowList }}"
  action = "keep"
}
{{ end }}
{{- (index .Values .Name).additionalMetricRelabelingRules }}
forward_to = [prometheus.remote_write.grafana_cloud_prometheus.receiver]
{{- end }}

{{ define "prometheus-collect" -}}
targets  = discovery.relabel.{{ .Name | replace "-" "_" }}.output
forward_to = [prometheus.relabel.{{ .Name | replace "-" "_" }}.receiver]
{{- with (index .Values .Name).scrape_interval }}
scrape_interval = {{ . | quote }}
{{- end }}
{{- end }}
