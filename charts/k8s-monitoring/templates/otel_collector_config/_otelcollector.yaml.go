{{ define "otelcollector.config.otelcollector" }}
- job_name: integrations/kubernetes/otel-collector
  scrape_interval: {{ .Values.metrics.scrapeInterval }}
  static_configs:
  - targets:
    - ${env:MY_POD_IP}:8888
  relabel_configs:
{{- if .Values.metrics.extraRelabelingRules }}
{{ .Values.metrics.extraRelabelingRules | indent 4 }}
{{- end }}
  metric_relabel_configs:
{{- if .Values.metrics.cost.allowList }}
    - action: keep
      source_labels: ["__name__"]
      regex: "up|otelcol_process_uptime"
{{- if .Values.metrics.extraMetricRelabelingRules }}
{{ .Values.metrics.extraMetricRelabelingRules | indent 4 }}
{{- end }}
{{- end }}
{{ end }}
