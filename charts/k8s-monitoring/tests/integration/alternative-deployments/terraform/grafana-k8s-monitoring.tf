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
      name  = "destinations[0].url"
      value = var.prometheus-url
    }, {
      name  = "destinations[0].auth.username"
      value = var.prometheus-username
    }, {
      name  = "destinations[0].auth.password"
      value = var.prometheus-password
    }, {
      name  = "destinations[1].url"
      value = var.loki-url
    }, {
      name  = "destinations[1].auth.username"
      value = var.loki-username
    }, {
      name  = "destinations[1].auth.password"
      value = var.loki-password
    }, {
      name  = "destinations[1].tenantId"
      value = var.loki-tenantid
    }
  ]
}