resource "helm_release" "grafana-k8s-monitoring" {
  name             = "grafana-k8s-monitoring"
  chart            = "../../../../../k8s-monitoring"
  namespace        = var.namespace
  create_namespace = true
  atomic           = true

  values = [file("values.yaml")]

  set {
    name  = "cluster.name"
    value = var.cluster-name
  }

  set {
    name  = "destinations[0].url"
    value = var.prometheus-url
  }

  set {
    name  = "destinations[0].auth.username"
    value = var.prometheus-username
  }

  set {
    name  = "destinations[0].auth.password"
    value = var.prometheus-password
  }

  set {
    name  = "destinations[1].url"
    value = var.loki-url
  }

  set {
    name  = "destinations[1].auth.username"
    value = var.loki-username
  }

  set {
    name  = "destinations[1].auth.password"
    value = var.loki-password
  }

  set {
    name  = "destinations[1].tenantId"
    value = var.loki-tenantid
  }
}