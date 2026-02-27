{{- define "feature.hostMetrics.notes.deployments" }}{{- end }}

{{- define "feature.hostMetrics.notes.task" }}
Scrape Kubernetes Host metrics
{{- end }}

{{- define "feature.hostMetrics.notes.actions" }}
{{/*{{- $serviceMonitorScrapingEnabled := and .Values.prometheusOperatorObjects.enabled (dig "serviceMonitors" "enabled" true .Values.prometheusOperatorObjects)}}*/}}
{{/*{{- $checkForKSMServiceMonitors := and (index .Values.clusterMetrics "kube-state-metrics").enabled (index .Values.clusterMetrics "kube-state-metrics").checkForPotentialServiceMonitorConflicts }}*/}}
{{/*{{- $checkForNodeExporterServiceMonitors := and (index .Values.clusterMetrics "node-exporter").enabled (index .Values.clusterMetrics "node-exporter").checkForPotentialServiceMonitorConflicts }}*/}}
{{/*{{- if and $serviceMonitorScrapingEnabled (or $checkForKSMServiceMonitors $checkForNodeExporterServiceMonitors) }}*/}}
{{/*  {{- $values := .Values.clusterMetrics }}*/}}
{{/*  {{- if (.Capabilities.APIVersions.Has "monitoring.coreos.com/v1/ServiceMonitor") }}*/}}
{{/*    {{- $namespaces := list }}*/}}
{{/*    {{- range $serviceMonitor := (lookup "monitoring.coreos.com/v1" "ServiceMonitor" "" "").items }}*/}}
{{/*      {{- if contains "kube-state-metrics" $serviceMonitor.metadata.name }}*/}}
{{/*        {{- if $checkForKSMServiceMonitors }}*/}}
{{/*          {{- $namespaces = append $namespaces $serviceMonitor.metadata.namespace }}*/}}
{{/*⚠️ Detected a ServiceMonitor named {{ $serviceMonitor.metadata.name }} in namespace {{ $serviceMonitor.metadata.namespace }}, but this chart has already enabled the Cluster Metrics feature. This might result in duplicated metrics from kube-state-metrics.*/}}
{{/*        {{- end }}*/}}
{{/*      {{- end }}*/}}
{{/*      {{- if contains "node-exporter" $serviceMonitor.metadata.name }}*/}}
{{/*        {{- if $checkForNodeExporterServiceMonitors }}*/}}
{{/*          {{- $namespaces = append $namespaces $serviceMonitor.metadata.namespace }}*/}}
{{/*⚠️ Detected a ServiceMonitor named {{ $serviceMonitor.metadata.name }} in namespace {{ $serviceMonitor.metadata.namespace }}, but this chart has already enabled the Cluster Metrics feature. This might result in duplicated metrics from Node Exporter.*/}}
{{/*        {{- end }}*/}}
{{/*      {{- end }}*/}}
{{/*    {{- end }}*/}}
{{/*  {{- if $namespaces }}*/}}
{{/*To prevent duplicate metrics, either delete the ServiceMonitor, or filter them out with:*/}}
{{/*prometheusOperatorObjects:*/}}
{{/*  serviceMonitors:*/}}
{{/*    excludeNamespaces:{{ $namespaces | uniq | toYaml | nindent 6 }}*/}}
{{/*OR*/}}
{{/*prometheusOperatorObjects:*/}}
{{/*  serviceMonitors:*/}}
{{/*    labelExpressions: <label expression to exclude the ServiceMonitor>*/}}
{{/*  {{- end }}*/}}
{{/*  {{- end }}*/}}
{{/*{{- end }}*/}}
{{- end }}

{{- define "feature.hostMetrics.summary" }}
{{- $sources := list }}
{{- if .Values.linuxHosts.enabled }}{{- $sources = append $sources "linuxHosts" }}{{ end }}
{{- if .Values.windowsHosts.enabled }}{{- $sources = append $sources "windowsHosts" }}{{ end }}
{{- if .Values.energyMetrics.enabled }}{{- $sources = append $sources "energyMetrics" }}{{ end }}
version: {{ .Chart.Version }}
sources: {{ $sources | join "," }}
{{- end }}
