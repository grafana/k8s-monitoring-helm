{{- define "feature.frontendObservability.module" }}
declare "frontend_observability" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  argument "traces_destinations" {
    comment = "Must be a list of trace destinations where collected trace should be forwarded to"
  }

  faro.receiver "frontend_observability" {
    server {
      listen_port = {{ .Values.port | int }}
    }

    output {
      logs = argument.logs_destinations.value
      traces = argument.traces_destinations.value
    }
  }
}
{{- end -}}
