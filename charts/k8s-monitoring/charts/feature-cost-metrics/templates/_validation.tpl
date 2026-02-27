{{- define "feature.costMetrics.validate" }}
  {{- if not (dig "opencost" "deploy" false (.telemetryServices | default dict)) }}
    {{- if not (or .Values.opencost.namespace .Values.opencost.labelMatchers) }}
      {{- $msg := list "" "The OpenCost configuration requires a connection to OpenCost" }}
      {{- $msg = append $msg "Please enable the built-in deployment:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- $msg = append $msg "    deploy: true" }}
      {{- $msg = append $msg "Or, set the namespace and label selectors for an existing OpenCost:" }}
      {{- $msg = append $msg "costMetrics:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- $msg = append $msg "    namespace: opencost-namespace" }}
      {{- $msg = append $msg "    labelSelectors:" }}
      {{- $msg = append $msg "      app.kubernetes.io/name: opencost" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
