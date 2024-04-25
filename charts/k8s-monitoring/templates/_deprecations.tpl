{{- define "checkForDeprecations" -}}
{{/*
v0.3.0: prometheus.remote_write.grafana_cloud_prometheus renamed

As of k8s-monitoring Chart version 0.3, the component "prometheus.remote_write.grafana_cloud_prometheus" has been renamed.
Please change your configurations to direct metric data to the "prometheus.relabel.metrics_service" component instead.
For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements
*/}}
{{- if or (contains "prometheus.remote_write.grafana_cloud_prometheus" .Values.extraConfig) (contains "prometheus.remote_write.grafana_cloud_prometheus" .Values.logs.extraConfig) }}
  {{ fail "\n\nAs of k8s-monitoring Chart version 0.3, the component \"prometheus.remote_write.grafana_cloud_prometheus\" has been renamed.\nPlease change your configurations to direct metric data to the \"prometheus.relabel.metrics_service\" component instead.\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements"}}
{{- end -}}

{{/*
v0.7.0: traces.receivers moved to .receivers

As of k8s-monitoring Chart version 0.7, the ".traces.receivers" section has been moved to ".receivers".
Please update your values file and try again.
For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements
*/}}
{{- if index .Values.traces "receivers" -}}
  {{ fail "\n\nAs of k8s-monitoring Chart version 0.7, the \".traces.receivers\" section has been moved to \".receivers\".\nPlease update your values file and try again.\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements"}}
{{- end -}}

{{/*
v0.9.0: allowLists replaced by metricsTuning

As of k8s-monitoring Chart version 0.9, metric sources no longer utilize ".allowList".
Controlling the amount of metrics returned can be done with the ".metricsTuning" section.
Please update your values file and try again.
For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements
*/}}
{{- if or
  ((index .Values.metrics "agent").allowList)
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

{{/*
v0.12.0: loki.write.grafana_cloud_loki renamed

As of k8s-monitoring Chart version 0.12, the component "loki.write.grafana_cloud_loki" has been renamed.
Please change your configurations to direct log data to the "loki.process.logs_service" component instead.
For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements
*/}}
{{- if or (contains "loki.write.grafana_cloud_loki" .Values.extraConfig) (contains "loki.write.grafana_cloud_loki" .Values.logs.extraConfig) }}
  {{ fail "\n\nAs of k8s-monitoring Chart version 0.12, the component \"loki.write.grafana_cloud_loki\" has been renamed.\nPlease change your configurations to direct log data to the \"loki.process.logs_service\" component instead.\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements"}}
{{- end -}}

{{/*
v1.0.0: Grafana Agent replaced with Grafana Alloy

As of k8s-monitoring Chart version 1.0, Grafana Agent has been replaced with Grafana Alloy.
These sections in your values file will need to be renamed:
  grafana-agent          --> alloy
  grafana-agent-events   --> alloy-events
  grafana-agent-logs     --> alloy-logs
  grafana-agent-profiles --> alloy-profiles
  metrics.agent          --> metrics.alloy

For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements
*/}}
{{- if or
  (index .Values "grafana-agent")
  (index .Values "grafana-agent-events")
  (index .Values "grafana-agent-logs")
  (index .Values "grafana-agent-profiles")
  (index .Values.metrics "agent") }}
  {{ fail "\n\nAs of k8s-monitoring Chart version 1.0, Grafana Agent has been replaced with Grafana Alloy.\nThese sections in your values file will need to be renamed:\n  grafana-agent          --> alloy\n  grafana-agent-events   --> alloy-events\n  grafana-agent-logs     --> alloy-logs\n  grafana-agent-profiles --> alloy-profiles\n  metrics.agent          --> metrics.alloy\n\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements" }}
{{- end -}}

{{/*
v1.0.1: OpenCost changed how to reference an external secret

As of k8s-monitoring Chart version 1.0.1, OpenCost changed how to reference an external secret.
Please rename:
opencost:
  opencost:
    prometheus:
      secret_name: prometheus-k8s-monitoring
To:
opencost:
  opencost:
    prometheus:
      existingSecretName: prometheus-k8s-monitoring

For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements
*/}}
{{- if .Values.opencost.opencost.prometheus.secret_name }}
  {{ fail "\n\nAs of k8s-monitoring Chart version 1.0.1, OpenCost changed how to reference an external secret.\nPlease rename:\nopencost:\n  opencost:\n    prometheus:\n      secret_name: prometheus-k8s-monitoring\nTo:\nopencost:\n  opencost:\n    prometheus:\n      existingSecretName: prometheus-k8s-monitoring\n\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements" }}
{{- end -}}
{{- end -}}
