{{- define "checkForDeprecations" -}}
{{/* v0.3.0: prometheus.remote_write.grafana_cloud_prometheus renamed */}}
{{- if or (contains "prometheus.remote_write.grafana_cloud_prometheus" .Values.extraConfig) (contains "prometheus.remote_write.grafana_cloud_prometheus" .Values.logs.extraConfig) }}
  {{ fail "\n\nAs of k8s-monitoring Chart version 0.3, the component \"prometheus.remote_write.grafana_cloud_prometheus\" has been renamed.\nPlease change your configurations to direct metric data to the \"prometheus.relabel.metrics_service\" component instead.\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements"}}
{{- end -}}

{{/* v0.7.0: traces.receivers moved to .receivers */}}
{{- if index .Values.traces "receivers" -}}
  {{ fail "\n\nAs of k8s-monitoring Chart version 0.7, the \".traces.receivers\" section has been moved to \".receivers\".\nPlease update your values file and try again.\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements"}}
{{- end -}}

{{/* v0.9.0: allowLists replaced by metricsTuning */}}
{{- if or
  (index .Values.metrics.agent "allowList")
  ((index .Values.metrics "kube-state-metrics").allowList)
  ((index .Values.metrics "node-exporter").allowList)
  ((index .Values.metrics "windows-exporter").allowList)
  (index .Values.metrics.kubelet "allowList")
  (index .Values.metrics.cadvisor "allowList")
  (index .Values.metrics.apiserver "allowList")
  (index .Values.metrics.kubeControllerManager "allowList")
  (index .Values.metrics.kubeProxy "allowList")
  (index .Values.metrics.kubeScheduler "allowList")
  (index .Values.metrics.cost "allowList") }}
  {{ fail "\n\nAs of k8s-monitoring Chart version 0.9, metric sources no longer utilize \".allowList\".\nControlling the amount of metrics returned can be done with the \".metricsTuning\" section.\nPlease update your values file and try again.\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements"}}
{{- end -}}

{{/* v0.12.0: loki.write.grafana_cloud_loki renamed */}}
{{- if or (contains "loki.write.grafana_cloud_loki" .Values.extraConfig) (contains "loki.write.grafana_cloud_loki" .Values.logs.extraConfig) }}
  {{ fail "\n\nAs of k8s-monitoring Chart version 0.12, the component \"loki.write.grafana_cloud_loki\" has been renamed.\nPlease change your configurations to direct log data to the \"loki.process.logs_service\" component instead.\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements"}}
{{- end -}}

{{- end -}}
