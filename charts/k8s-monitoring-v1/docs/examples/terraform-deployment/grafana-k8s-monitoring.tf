resource "helm_release" "grafana-k8s-monitoring" {
  name             = "grafana-k8s-monitoring"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "k8s-monitoring"
  namespace        = var.namespace
  create_namespace = true
  atomic           = true

  set {
    name  = "cluster.name"
    value = var.cluster-name
  }

  set {
    name  = "externalServices.prometheus.host"
    value = var.prometheus-url
  }

  set {
    name  = "externalServices.prometheus.basicAuth.username"
    value = var.prometheus-username
  }

  set {
    name  = "externalServices.prometheus.basicAuth.password"
    value = var.prometheus-password
  }

  set {
    name  = "externalServices.loki.host"
    value = var.loki-url
  }

  set {
    name  = "externalServices.loki.basicAuth.username"
    value = var.loki-username
  }

  set {
    name  = "externalServices.loki.basicAuth.password"
    value = var.loki-password
  }

  set {
    name  = "externalServices.tempo.host"
    value = var.tempo-url
  }

  set {
    name  = "externalServices.tempo.basicAuth.username"
    value = var.tempo-username
  }

  set {
    name  = "externalServices.tempo.basicAuth.password"
    value = var.tempo-password
  }

  set {
    name  = "traces.enabled"
    value = true
  }

  set {
    name  = "opencost.opencost.exporter.defaultClusterId"
    value = var.cluster-name
  }

  set {
    name  = "opencost.opencost.prometheus.external.url"
    value = "${var.prometheus-url}/api/prom"
  }
}
