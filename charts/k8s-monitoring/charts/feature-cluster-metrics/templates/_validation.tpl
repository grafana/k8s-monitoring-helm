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
      {{- $msg = append $msg "Or, set the namespace and label matchers for an existing kube-state-metrics:" }}
      {{- $msg = append $msg "clusterMetrics:" }}
      {{- $msg = append $msg "  kube-state-metrics:" }}
      {{- $msg = append $msg "    namespace: kube-state-metrics-namespace" }}
      {{- $msg = append $msg "    labelMatchers:" }}
      {{- $msg = append $msg "      app.kubernetes.io/name: kube-state-metrics" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Check for settings from features that have moved out of clusterMetrics in v4.x */}}
{{- if hasKey .Values "node-exporter" }}
  {{- $msg := list "" "The key \"node-exporter\" found under clusterMetrics is no longer valid." }}
  {{- $msg = append $msg "In v4.x, Node Exporter settings have moved to the hostMetrics feature and telemetryServices." }}
  {{- $msg = append $msg "Please use:" }}
  {{- $msg = append $msg "hostMetrics:" }}
  {{- $msg = append $msg "  linuxHosts:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "    ...  # scrape settings" }}
  {{- $msg = append $msg "telemetryServices:" }}
  {{- $msg = append $msg "  node-exporter:" }}
  {{- $msg = append $msg "    deploy: true" }}
  {{- $msg = append $msg "    ...  # deployment settings" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- if hasKey .Values "windows-exporter" }}
  {{- $msg := list "" "The key \"windows-exporter\" found under clusterMetrics is no longer valid." }}
  {{- $msg = append $msg "In v4.x, Windows Exporter settings have moved to the hostMetrics feature and telemetryServices." }}
  {{- $msg = append $msg "Please use:" }}
  {{- $msg = append $msg "hostMetrics:" }}
  {{- $msg = append $msg "  windowsHosts:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "    ...  # scrape settings" }}
  {{- $msg = append $msg "telemetryServices:" }}
  {{- $msg = append $msg "  windows-exporter:" }}
  {{- $msg = append $msg "    deploy: true" }}
  {{- $msg = append $msg "    ...  # deployment settings" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- if hasKey .Values "opencost" }}
  {{- $msg := list "" "The key \"opencost\" found under clusterMetrics is no longer valid." }}
  {{- $msg = append $msg "In v4.x, OpenCost settings have moved to the costMetrics feature and telemetryServices." }}
  {{- $msg = append $msg "Please use:" }}
  {{- $msg = append $msg "costMetrics:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- $msg = append $msg "  ...  # scrape settings" }}
  {{- $msg = append $msg "telemetryServices:" }}
  {{- $msg = append $msg "  opencost:" }}
  {{- $msg = append $msg "    deploy: true" }}
  {{- $msg = append $msg "    ...  # deployment settings" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- if hasKey .Values "kepler" }}
  {{- $msg := list "" "The key \"kepler\" found under clusterMetrics is no longer valid." }}
  {{- $msg = append $msg "In v4.x, Kepler settings have moved to the hostMetrics feature and telemetryServices." }}
  {{- $msg = append $msg "Please use:" }}
  {{- $msg = append $msg "hostMetrics:" }}
  {{- $msg = append $msg "  energyMetrics:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "    ...  # scrape settings" }}
  {{- $msg = append $msg "telemetryServices:" }}
  {{- $msg = append $msg "  kepler:" }}
  {{- $msg = append $msg "    deploy: true" }}
  {{- $msg = append $msg "    ...  # deployment settings" }}
  {{- fail (join "\n" $msg) }}
{{- end }}

{{/* Check for deployment-level settings accidentally placed under clusterMetrics.kube-state-metrics */}}
{{- $deploymentKeys := list "autosharding" "collectors" "customLabels" "customResourceState" "deploy" "extraArgs" "image" "nodeSelector" "podAnnotations" "prometheusScrape" "rbac" "releaseLabel" "replicas" "resources" "tolerations" "updateStrategy" }}
{{- range $key := $deploymentKeys }}
  {{- if hasKey $ksmSettings $key }}
    {{- $msg := list "" (printf "The key \"%s\" found under clusterMetrics.kube-state-metrics is a deployment-level setting." $key) }}
    {{- $msg = append $msg "In v4.x, deployment settings for kube-state-metrics have moved to telemetryServices." }}
    {{- $msg = append $msg "Please move this setting:" }}
    {{- $msg = append $msg "telemetryServices:" }}
    {{- $msg = append $msg "  kube-state-metrics:" }}
    {{- $msg = append $msg (printf "    %s: ..." $key) }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}
