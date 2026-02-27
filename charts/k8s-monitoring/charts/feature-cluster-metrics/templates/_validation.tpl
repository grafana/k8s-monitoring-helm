{{- define "feature.clusterMetrics.validate" }}
{{- $ksmSettings := (index .Values "kube-state-metrics") }}
{{- if $ksmSettings.enabled }}
  {{- if not (dig "kube-state-metrics" "deploy" false (.telemetryServices | default dict)) }}
    {{- if not (or $ksmSettings.namespace $ksmSettings.labelMatchers) }}
      {{- $msg := list "" "The kube-state-metrics configuration requires a connection to kube-state-metrics" }}
      {{- $msg = append $msg "Please enable the built-in deployment:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  kube-state-metrics:" }}
      {{- $msg = append $msg "    deploy: true" }}
      {{- $msg = append $msg "Or, set the namespace and label selectors for an existing kube-state-metrics:" }}
      {{- $msg = append $msg "clusterMetrics:" }}
      {{- $msg = append $msg "  kube-state-metrics:" }}
      {{- $msg = append $msg "    namespace: kube-state-metrics-namespace" }}
      {{- $msg = append $msg "    labelSelectors:" }}
      {{- $msg = append $msg "      app.kubernetes.io/name: kube-state-metrics" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}{{- end }}
