{{- define "feature.annotationAutodiscovery.validate" }}
{{- if and (not .Values.pods.enabled) (not .Values.services.enabled) }}
  {{- $msg := list "" "Either Pods or Services must be enabled for this feature to work." }}
  {{- $msg = append $msg "Please enable one or both. For example:" }}
  {{- $msg = append $msg "annotationAutodiscovery:" }}
  {{- $msg = append $msg "  pods:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "AND/OR" }}
  {{- $msg = append $msg "  services:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-annotation-autodiscovery for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
