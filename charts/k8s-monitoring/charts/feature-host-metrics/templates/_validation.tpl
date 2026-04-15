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

{{/* Check for deployment-level settings accidentally placed under hostMetrics.linuxHosts (node-exporter) */}}
{{- $nodeExporterDeploymentKeys := list "affinity" "configmaps" "containerSecurityContext" "deploy" "dnsConfig" "env" "extraArgs" "extraHostVolumeMounts" "extraInitContainers" "extraVolumeMounts" "extraVolumes" "hostNetwork" "hostPID" "image" "imagePullSecrets" "nodeSelector" "podAnnotations" "podLabels" "rbac" "releaseLabel" "resources" "secrets" "securityContext" "serviceAccount" "tolerations" "updateStrategy" }}
{{- range $key := $nodeExporterDeploymentKeys }}
  {{- if hasKey $.Values.linuxHosts $key }}
    {{- $msg := list "" (printf "The key \"%s\" found under hostMetrics.linuxHosts is a deployment-level setting." $key) }}
    {{- $msg = append $msg "In v4.x, deployment settings for Node Exporter have moved to telemetryServices." }}
    {{- $msg = append $msg "Please move this setting:" }}
    {{- $msg = append $msg "telemetryServices:" }}
    {{- $msg = append $msg "  node-exporter:" }}
    {{- $msg = append $msg (printf "    %s: ..." $key) }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}

{{/* Check for deployment-level settings accidentally placed under hostMetrics.windowsHosts (windows-exporter) */}}
{{- $windowsExporterDeploymentKeys := list "affinity" "config" "configmaps" "containerSecurityContext" "deploy" "dnsConfig" "env" "extraArgs" "extraHostVolumeMounts" "extraInitContainers" "hostNetwork" "hostPID" "image" "imagePullSecrets" "nodeSelector" "podAnnotations" "podLabels" "rbac" "releaseLabel" "resources" "secrets" "securityContext" "serviceAccount" "tolerations" "updateStrategy" }}
{{- range $key := $windowsExporterDeploymentKeys }}
  {{- if hasKey $.Values.windowsHosts $key }}
    {{- $msg := list "" (printf "The key \"%s\" found under hostMetrics.windowsHosts is a deployment-level setting." $key) }}
    {{- $msg = append $msg "In v4.x, deployment settings for Windows Exporter have moved to telemetryServices." }}
    {{- $msg = append $msg "Please move this setting:" }}
    {{- $msg = append $msg "telemetryServices:" }}
    {{- $msg = append $msg "  windows-exporter:" }}
    {{- $msg = append $msg (printf "    %s: ..." $key) }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}

{{/* Check for deployment-level settings accidentally placed under hostMetrics.energyMetrics (kepler) */}}
{{- $keplerDeploymentKeys := list "affinity" "annotations" "canMount" "deploy" "extraEnvVars" "image" "imagePullSecrets" "modelServer" "networkPolicy" "nodeSelector" "podAnnotations" "podLabels" "podSecurityContext" "rbac" "redfish" "resources" "securityContext" "serviceAccount" "serviceMonitor" "tolerations" }}
{{- range $key := $keplerDeploymentKeys }}
  {{- if hasKey $.Values.energyMetrics $key }}
    {{- $msg := list "" (printf "The key \"%s\" found under hostMetrics.energyMetrics is a deployment-level setting." $key) }}
    {{- $msg = append $msg "In v4.x, deployment settings for Kepler have moved to telemetryServices." }}
    {{- $msg = append $msg "Please move this setting:" }}
    {{- $msg = append $msg "telemetryServices:" }}
    {{- $msg = append $msg "  kepler:" }}
    {{- $msg = append $msg (printf "    %s: ..." $key) }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}
