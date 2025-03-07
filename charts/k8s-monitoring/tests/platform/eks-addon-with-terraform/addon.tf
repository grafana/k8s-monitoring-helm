resource "aws_eks_addon" "default" {
  cluster_name          = var.cluster-name
  addon_name            = "grafana-labs_kubernetes-monitoring"
}
