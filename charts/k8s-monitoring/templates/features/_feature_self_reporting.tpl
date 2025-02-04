{{- define "features.selfReporting.enabled" -}}
{{- $metricsDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.selfReporting.destinations) | fromYamlArray -}}
{{ and .Values.selfReporting.enabled (not (empty $metricsDestinations)) }}
{{- end -}}

{{- define "features.selfReporting.collectors" -}}
{{- if eq (include "features.selfReporting.enabled" .) "true" }}
  {{- $collectorsByIncreasingPreference := list "alloy-receiver" "alloy-metrics" "alloy-singleton" }}
  {{- $chosenCollector := "" }}
  {{- range $collector := $collectorsByIncreasingPreference }}
    {{- if (index $.Values $collector).enabled }}{{- $chosenCollector = $collector }}{{- end -}}
  {{- end -}}
- {{ $chosenCollector }}
  {{- end -}}
{{- end }}

{{- define "features.selfReporting.destinations" }}
{{- if eq (include "features.selfReporting.enabled" .) "true" }}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.selfReporting.destinations) -}}
{{- end }}
{{- end }}

{{- define "features.selfReporting.validate" }}{{ end }}
{{- define "features.selfReporting.include" }}
{{- if eq (include "features.selfReporting.enabled" .) "true" }}
{{- $destinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.selfReporting.destinations) | fromYamlArray -}}

// Self Reporting
prometheus.exporter.unix "kubernetes_monitoring_telemetry" {
  set_collectors = ["textfile"]
  textfile {
    directory = "/etc/alloy"
  }
}

discovery.relabel "kubernetes_monitoring_telemetry" {
  targets = prometheus.exporter.unix.kubernetes_monitoring_telemetry.targets
  rule {
    target_label = "instance"
    action = "replace"
    replacement = "{{ .Release.Name }}"
  }
  rule {
    target_label = "job"
    action = "replace"
    replacement = "integrations/kubernetes/kubernetes_monitoring_telemetry"
  }
}

prometheus.scrape "kubernetes_monitoring_telemetry" {
  job_name   = "integrations/kubernetes/kubernetes_monitoring_telemetry"
  targets    = discovery.relabel.kubernetes_monitoring_telemetry.output
  scrape_interval = {{ .Values.selfReporting.scrapeInterval | default .Values.global.scrapeInterval | quote}}
  clustering {
    enabled = true
  }
  forward_to = [prometheus.relabel.kubernetes_monitoring_telemetry.receiver]
}

prometheus.relabel "kubernetes_monitoring_telemetry" {
  rule {
    source_labels = ["__name__"]
    regex = "grafana_kubernetes_monitoring_.*"
    action = "keep"
  }
  forward_to = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end }}
{{- end }}

{{- define "features.selfReporting.metrics" }}
{{- if eq (include "features.selfReporting.enabled" .) "true" }}
# HELP grafana_kubernetes_monitoring_build_info A metric to report the version of the Kubernetes Monitoring Helm chart
# TYPE grafana_kubernetes_monitoring_build_info gauge
grafana_kubernetes_monitoring_build_info{version="{{ .Chart.Version }}", namespace="{{ .Release.Namespace }}"{{- if .Values.global.platform }}, platform="{{ .Values.global.platform }}"{{ end }}} 1
# HELP grafana_kubernetes_monitoring_feature_info A metric to report the enabled features of the Kubernetes Monitoring Helm chart
# TYPE grafana_kubernetes_monitoring_feature_info gauge
{{- range $feature := include "features.list.enabled" . | fromYamlArray }}
  {{- if ne $feature "selfReporting" }}
    {{- $featureSummary := include (printf "feature.%s.summary" $feature) (dict "Chart" (index $.Subcharts $feature).Chart "Values" (index $.Values $feature)) | fromYaml }}
grafana_kubernetes_monitoring_feature_info{{ include "label_list" (merge $featureSummary (dict "feature" $feature)) }} 1
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "feature.selfReporting.alloyModules" }}{{ end }}
{{- define "feature.selfReporting.notes.deployments" }}{{ end }}
{{- define "feature.selfReporting.notes.task" }}{{ end }}
{{- define "feature.selfReporting.notes.actions" }}{{ end }}
