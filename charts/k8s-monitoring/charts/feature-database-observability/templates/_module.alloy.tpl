{{- define "feature.databaseObservability.module" }}
declare "database_observability" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }

{{- range $instance := $.Values.instances }}
  {{- if eq $instance.type "mysql" }}
    {{- include "databaseObservability.mysql.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}
}
{{- end }}
