{{- define "checkForDeprecations" -}}
{{- if index .Values.traces "receivers" -}}
  {{ fail "As of k8s-monitoring Chart version 0.7, the \".traces.receivers\" section has been moved to \".receivers\".\nPlease update your values file and try again.\nFor more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements"}}
{{- end -}}
{{- end -}}
