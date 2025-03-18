terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}
provider "helm" {
  kubernetes {
    # Replace this with values that provide connection to your cluster
    config_path    = "~/.kube/config"
    config_context = "my-cluster-context"
  }
}
