{{- define "feature.prometheusOperatorObjects.notes.deployments" }}
{{- if .Values.crds.deploy }}
* Prometheus Operator CRDs (CustomResourceDefinitions)
{{- end }}
{{- end }}

{{- define "feature.prometheusOperatorObjects.notes.task" }}
{{- $sources := list }}
{{- if .Values.serviceMonitors.enabled }}{{- $sources = append $sources "ServiceMonitors" }}{{- end }}
{{- if .Values.podMonitors.enabled }}{{- $sources = append $sources "PodMonitors" }}{{- end }}
{{- if .Values.probes.enabled }}{{- $sources = append $sources "Probes" }}{{- end }}
Scrapes metrics from {{ include "english_list" $sources }}.
{{- end }}

{{- define "feature.prometheusOperatorObjects.notes.actions" }}{{- end }}

{{- define "feature.prometheusOperatorObjects.summary" -}}
{{- $sources := list }}
{{- if .Values.serviceMonitors.enabled }}{{- $sources = append $sources "ServiceMonitors" }}{{- end }}
{{- if .Values.podMonitors.enabled }}{{- $sources = append $sources "PodMonitors" }}{{- end }}
{{- if .Values.probes.enabled }}{{- $sources = append $sources "Probes" }}{{- end }}
version: {{ .Chart.Version }}
sources: {{ $sources | join "," }}
{{- end }}
