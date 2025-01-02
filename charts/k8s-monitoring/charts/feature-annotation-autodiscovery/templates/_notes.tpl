{{- define "feature.annotationAutodiscovery.notes.deployments" }}{{- end }}

{{- define "feature.annotationAutodiscovery.notes.task" }}
Scrape metrics from pods and services with the "{{.Values.annotations.scrape}}: true" annotation
{{- end }}

{{- define "feature.annotationAutodiscovery.notes.actions" }}{{- end }}

{{- define "feature.annotationAutodiscovery.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
