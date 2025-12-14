{{- define "feature.kubernetesManifests.pods" }}
otelcol.receiver.filelog "pod_manifests" {
  include = ["/var/kubernetes-manifests/pods/*/*.json"]
  include_file_path_resolved = true
  start_at = "beginning"
  delete_after_read = true

  output {
    logs = [otelcol.processor.transform.pod_manifests.input]
  }
}

otelcol.processor.transform "pod_manifests" {
  error_mode = "ignore"

  log_statements {
    context = "log"
    statements = [
      `merge_maps(attributes, ExtractPatterns(log.attributes["log.file.path_resolved"], "^/var/kubernetes-manifests/pods/(?P<namespace>[^/]+)/(?P<pod>[^.]+)\\.json$"), "upsert")`,
      `set(resource.attributes["k8s.namespace.name"], attributes["namespace"])`,
      `set(resource.attributes["k8s.pod.name"], attributes["pod"])`,
      `set(resource.attributes["service.name"], "k8s.grafana.com/manifest-collector")`,
      `set(resource.attributes["service.namespace"], {{ $.Release.Namespace | quote }})`,
    ]
  }

  output {
    logs = [otelcol.processor.k8sattributes.pod_manifests.input]
  }
}

otelcol.processor.k8sattributes "pod_manifests" {
  pod_association {
    source {
      from = "resource_attribute"
      name = "k8s.pod.name"
    }
    source {
      from = "resource_attribute"
      name = "k8s.namespace.name"
    }
  }

  extract {
    metadata = [
      "k8s.cronjob.name",
      "k8s.daemonset.name",
      "k8s.deployment.name",
      "k8s.job.name",
      "k8s.node.name",
      "k8s.pod.start_time",
      "k8s.replicaset.name",
      "k8s.statefulset.name",
    ]
  }

  output {
    logs = argument.logs_destinations.value
  }
}
{{- end -}}
