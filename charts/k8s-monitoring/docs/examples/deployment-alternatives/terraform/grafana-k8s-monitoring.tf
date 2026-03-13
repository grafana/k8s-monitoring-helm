resource "helm_release" "grafana-k8s-monitoring" {
  name             = "grafana-k8s-monitoring"
  chart            = "../../../../../k8s-monitoring"
  namespace        = var.namespace
  create_namespace = true
  atomic           = true

  values = [file("values.yaml")]

  set = [
    {
      name  = "cluster.name"
      value = var.cluster-name
    }, {
      name  = "destinations.localPrometheus.url"
      value = var.prometheus-url
    }, {
      name  = "destinations.localPrometheus.auth.username"
      value = var.prometheus-username
    }, {
      name  = "destinations.localPrometheus.auth.password"
      value = var.prometheus-password
    }, {
      name  = "destinations.localLoki.url"
      value = var.loki-url
    }, {
      name  = "destinations.localLoki.auth.username"
      value = var.loki-username
    }, {
      name  = "destinations.localLoki.auth.password"
      value = var.loki-password
    }, {
      name  = "destinations.localLoki.tenantId"
      value = var.loki-tenantid
    }
  ]
}