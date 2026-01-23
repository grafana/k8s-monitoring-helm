{{- define "feature.kubernetesManifests.workload" }}
otelcol.receiver.filelog "{{ .kind }}_manifests" {
  include = ["/var/kubernetes-manifests/{{ .kind }}s/*/*.json"]
  include_file_path_resolved = true
  start_at = "beginning"
  delete_after_read = true

  output {
    logs = [otelcol.processor.transform.{{ .kind }}_manifests.input]
  }
}

otelcol.processor.transform "{{ .kind }}_manifests" {
  error_mode = "ignore"

  log_statements {
    context = "log"
    statements = [
      `merge_maps(attributes, ExtractPatterns(log.attributes["log.file.path_resolved"], "^/var/kubernetes-manifests/{{ .kind }}s/(?P<namespace>[^/]+)/(?P<{{ .kind }}>[^.]+)\\.json$"), "upsert")`,
      `set(resource.attributes["k8s.namespace.name"], attributes["namespace"])`,
      `set(resource.attributes["k8s.{{ .kind }}.name"], attributes["{{ .kind }}"])`,
      `set(resource.attributes["service.name"], "k8s.grafana.com/manifest-collector")`,
      `set(resource.attributes["service.namespace"], {{ $.Release.Namespace | quote }})`,
    ]
  }

  output {
    logs = argument.logs_destinations.value
  }
}
{{- end -}}
