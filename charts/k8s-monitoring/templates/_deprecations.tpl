{{- define "checkForDeprecations" -}}
{{- if index .Values.traces "receivers" -}}
  {{ fail "\n\nAs of k8s-monitoring Chart version 0.7, the \".traces.receivers\" section has been moved to \".receivers\".\nPlease update your values file and try again.\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements"}}
{{- end -}}

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
{{- end -}}
