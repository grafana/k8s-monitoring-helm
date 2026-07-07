{{- define "feature.costMetrics.validate" }}
  {{- if not (dig "opencost" "deploy" false (.telemetryServices | default dict)) }}
    {{- if not .Values.opencost.labelMatchers }}
      {{- $msg := list "" "The OpenCost configuration requires a connection to OpenCost" }}
      {{- $msg = append $msg "Please enable the built-in deployment:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- $msg = append $msg "    deploy: true" }}
      {{- $msg = append $msg "Or, set the label matchers (and optionally a namespace) for an existing OpenCost:" }}
      {{- $msg = append $msg "costMetrics:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- $msg = append $msg "    labelMatchers:" }}
      {{- $msg = append $msg "      app.kubernetes.io/name: opencost" }}
      {{- $msg = append $msg "    namespace: opencost-namespace" }}
      {{- fail (join "\n" $msg) }}
    {{- else }}
      {{- include "feature.validateLabelMatchersFindPods" (dict "namespace" .Values.opencost.namespace "labelMatchers" .Values.opencost.labelMatchers "serviceName" "OpenCost") }}
    {{- end }}
  {{- end }}
{{- end }}
