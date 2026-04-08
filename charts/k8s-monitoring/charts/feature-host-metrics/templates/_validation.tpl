{{- define "feature.hostMetrics.validate" }}
{{- if .Values.linuxHosts.enabled }}
  {{- if not (dig "node-exporter" "deploy" false (.telemetryServices | default dict)) }}
    {{- if not (or .Values.linuxHosts.namespace .Values.linuxHosts.labelMatchers) }}
      {{- $msg := list "" "The Linux host configuration requires a connection to Node Exporter" }}
      {{- $msg = append $msg "Please enable the built-in deployment:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  node-exporter:" }}
      {{- $msg = append $msg "    deploy: true" }}
      {{- $msg = append $msg "Or, set the namespace and label selectors for an existing Node Exporter:" }}
      {{- $msg = append $msg "hostMetrics:" }}
      {{- $msg = append $msg "  linuxHosts:" }}
      {{- $msg = append $msg "    namespace: node-exporter-namespace" }}
      {{- $msg = append $msg "    labelSelectors:" }}
      {{- $msg = append $msg "      app.kubernetes.io/name: prometheus-node-exporter" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if .Values.windowsHosts.enabled }}
  {{- if not (dig "windows-exporter" "deploy" false (.telemetryServices | default dict)) }}
    {{- if not (or .Values.windowsHosts.namespace .Values.windowsHosts.labelMatchers) }}
      {{- $msg := list "" "The Windows host configuration requires a connection to Windows Exporter" }}
      {{- $msg = append $msg "Please enable the built-in deployment:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  windows-exporter:" }}
      {{- $msg = append $msg "    deploy: true" }}
      {{- $msg = append $msg "Or, set the namespace and label selectors for an existing Windows Exporter:" }}
      {{- $msg = append $msg "hostMetrics:" }}
      {{- $msg = append $msg "  windowsHosts:" }}
      {{- $msg = append $msg "    namespace: windows-exporter-namespace" }}
      {{- $msg = append $msg "    labelSelectors:" }}
      {{- $msg = append $msg "      app.kubernetes.io/name: prometheus-windows-exporter" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if .Values.energyMetrics.enabled }}
  {{- if not (dig "kepler" "deploy" false (.telemetryServices | default dict)) }}
    {{- if not (or .Values.energyMetrics.namespace .Values.energyMetrics.labelMatchers) }}
      {{- $msg := list "" "The host energy metrics configuration requires a connection to Kepler" }}
      {{- $msg = append $msg "Please enable the built-in deployment:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  kepler:" }}
      {{- $msg = append $msg "    deploy: true" }}
      {{- $msg = append $msg "Or, set the namespace and label selectors for an existing Kepler:" }}
      {{- $msg = append $msg "hostMetrics:" }}
      {{- $msg = append $msg "  energyMetrics:" }}
      {{- $msg = append $msg "    namespace: kepler-namespace" }}
      {{- $msg = append $msg "    labelSelectors:" }}
      {{- $msg = append $msg "      app.kubernetes.io/name: kepler" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
