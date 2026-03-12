{{ define "feature.prometheusOperatorObjects.validate" -}}
{{ if and (not .Values.podMonitors.enabled) (not .Values.probes.enabled) (not .Values.serviceMonitors.enabled) (not .Values.scrapeConfigs.enabled) }}
  {{- $msg := list "" "At least one of ServiceMonitors, PodMonitors, Probes, or ScrapeConfigs must be enabled." }}
  {{- $msg = append $msg "Please enable at least one of the following:" }}
  {{- $msg = append $msg "prometheusOperatorObjects:" }}
  {{- $msg = append $msg "  serviceMonitors:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "  podMonitors:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "  probes:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "  scrapeConfigs:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}

{{- if .Values.crds }}
  {{- if .Values.crds.enabled }}
    {{- $msg := list "" "The Prometheus Operator Objects feature no longer incldues the CRDs." }}
    {{- $msg = append $msg "Please remove the `crds` block from your values file, or set `enabled` to false:" }}
    {{- $msg = append $msg "prometheusOperatorObjects:" }}
    {{- $msg = append $msg "  crds:" }}
    {{- $msg = append $msg "    enabled: true" }}
    {{- $msg = append $msg "" }}
    {{- $msg = append $msg "To deploy the CRDs manually, you can deploy its Helm chart directly: https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-operator-crds" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}
