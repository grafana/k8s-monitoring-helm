{{- define "features.selfReporting.enabled" -}}
{{- $metricsDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.selfReporting.destinations) | fromYamlArray -}}
{{ and .Values.selfReporting.enabled (not (empty $metricsDestinations)) }}
{{- end -}}

{{- define "features.selfReporting.chooseCollector" }}
{{- if eq (include "features.selfReporting.enabled" .) "true" }}
  {{- $enabledCollectors := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $chosenCollector := "" }}
  {{- range $collectorName := $enabledCollectors }}
    {{- $collectorValues := get $.Values.collectors $collectorName | default dict }}
    {{- if and (not $chosenCollector) (has "singleton" ($collectorValues.presets | default list)) }}
      {{- $chosenCollector = $collectorName }}
    {{- end }}
  {{- end }}
  {{- if not $chosenCollector }}
    {{- range $featureKey := include "features.list" $ | fromYamlArray }}
      {{- if and (ne $featureKey "selfReporting") (not $chosenCollector) }}
        {{- $destinationNames := ((include (printf "features.%s.destinations" $featureKey) $) | fromYamlArray) }}
        {{- range $destinationName := $destinationNames }}
          {{- if and (eq (include "destination.supportsMetrics" (deepCopy $ | merge (dict "destinationName" $destinationName)) | trim) "true") (not $chosenCollector) }}
            {{- $chosenCollector = include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if and (not $chosenCollector) (gt (len $enabledCollectors) 0) }}
    {{- $chosenCollector = index $enabledCollectors 0 }}
  {{- end }}
{{- $chosenCollector -}}
{{- end }}
{{- end }}

{{- define "features.selfReporting.destinations" }}
{{- if eq (include "features.selfReporting.enabled" .) "true" }}
  {{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.selfReporting.destinations) -}}
{{- end }}
{{- end }}

{{- define "features.selfReporting.collector.values" }}
{{- if eq (include "features.selfReporting.enabled" .) "true" }}
  {{- $collectorName := include "features.selfReporting.chooseCollector" . | trim }}
  {{- $collectorValues := (include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml) }}
  {{- $configMapName := printf "%s-release-info" (include "helper.fullname" .) }}
  {{- $extraMounts := deepCopy (dig "alloy" "mounts" "extra" list $collectorValues) }}
  {{- $extraMounts = append $extraMounts (dict "name" "release-info" "mountPath" "/etc/release-info" "readOnly" true) }}
  {{- $extraVolumes := deepCopy (dig "controller" "volumes" "extra" list $collectorValues) }}
  {{- $extraVolumes = append $extraVolumes (dict "name" "release-info" "configMap" (dict "name" $configMapName)) }}
collectors:
  {{ $collectorName }}:
    alloy:
      mounts:
        extra: {{ $extraMounts | toYaml | nindent 10 }}
    controller:
      volumes:
        extra: {{ $extraVolumes | toYaml | nindent 10 }}
{{- end }}
{{- end }}
{{- define "features.selfReporting.validate" }}{{ end }}
{{- define "features.selfReporting.include" }}
{{- if eq (include "features.selfReporting.enabled" .) "true" }}
{{- $destinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.selfReporting.destinations) | fromYamlArray -}}

// Self Reporting
prometheus.exporter.unix "kubernetes_monitoring_telemetry" {
  set_collectors = ["textfile"]
  textfile {
    directory = "/etc/release-info"
  }
} // prometheus.exporter.unix "kubernetes_monitoring_telemetry"

discovery.relabel "kubernetes_monitoring_telemetry" {
  targets = prometheus.exporter.unix.kubernetes_monitoring_telemetry.targets
  rule {
    target_label = "instance"
    action = "replace"
    replacement = "{{ .Release.Name }}"
  }
  rule {
    target_label = "job"
    action = "replace"
    replacement = "integrations/kubernetes/kubernetes_monitoring_telemetry"
  }
} // discovery.relabel "kubernetes_monitoring_telemetry"

prometheus.scrape "kubernetes_monitoring_telemetry" {
  job_name   = "integrations/kubernetes/kubernetes_monitoring_telemetry"
  targets    = discovery.relabel.kubernetes_monitoring_telemetry.output
  scrape_interval = {{ .Values.selfReporting.scrapeInterval | default .Values.global.scrapeInterval | quote}}
  clustering {
    enabled = true
  }
  forward_to = [prometheus.relabel.kubernetes_monitoring_telemetry.receiver]
} // prometheus.scrape "kubernetes_monitoring_telemetry"

prometheus.relabel "kubernetes_monitoring_telemetry" {
  rule {
    source_labels = ["__name__"]
    regex = "grafana_kubernetes_monitoring_.*"
    action = "keep"
  }
  forward_to = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
} // prometheus.relabel "kubernetes_monitoring_telemetry"
{{- end }}
{{- end }}

{{- define "features.selfReporting.metrics" }}
{{- if eq (include "features.selfReporting.enabled" .) "true" }}
# HELP grafana_kubernetes_monitoring_build_info A metric to report the version of the Kubernetes Monitoring Helm chart
# TYPE grafana_kubernetes_monitoring_build_info gauge
grafana_kubernetes_monitoring_build_info{version="{{ .Chart.Version }}", namespace="{{ include "helper.namespace" . }}"{{- if .Values.global.platform }}, platform="{{ .Values.global.platform }}"{{ end }}} 1
# HELP grafana_kubernetes_monitoring_feature_info A metric to report the enabled features of the Kubernetes Monitoring Helm chart
# TYPE grafana_kubernetes_monitoring_feature_info gauge
{{- range $feature := include "features.list.enabled" . | fromYamlArray }}
  {{- if ne $feature "selfReporting" }}
    {{- $featureSummary := include (printf "feature.%s.summary" $feature) (dict "Chart" (index $.Subcharts $feature).Chart "Values" (index $.Values $feature)) | fromYaml }}
grafana_kubernetes_monitoring_feature_info{{ include "label_list" (merge $featureSummary (dict "feature" $feature)) }} 1
    {{- end }}
  {{- end }}
# HELP grafana_kubernetes_monitoring_collector_info A metric to report the collectors of the Kubernetes Monitoring Helm chart
# TYPE grafana_kubernetes_monitoring_collector_info gauge
{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $collectorValues := get $.Values.collectors $collectorName | default dict }}
  {{- $resolvedValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- $kind := dig "controller" "type" "deployment" $resolvedValues }}
  {{- $presets := join "," ($collectorValues.presets | default list) }}
  {{- $labels := dict "name" $collectorName "type" "alloy" "kind" $kind "presets" $presets }}
  {{- if ne $kind "daemonset" }}
    {{- $replicas := dig "controller" "replicas" 1 $resolvedValues }}
    {{- $_ := set $labels "replicas" (printf "%d" (int $replicas)) }}
  {{- end }}
grafana_kubernetes_monitoring_collector_info{{ include "label_list" $labels }} 1
{{- end }}
# EOF
{{- end }}
{{- end }}

{{- define "feature.selfReporting.notes.deployments" }}{{ end }}
{{- define "feature.selfReporting.notes.task" }}{{ end }}
{{- define "feature.selfReporting.notes.actions" }}{{ end }}
