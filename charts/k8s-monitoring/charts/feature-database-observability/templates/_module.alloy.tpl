{{- define "feature.databaseObservability.module" }}
declare "db_observability" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }
{{- range $instance := $.Values.mysql.instances }}
  {{- include "databaseObservability.mysql.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
{{- end }}
}
{{- end }}
