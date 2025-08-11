terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
  }
}
provider "helm" {
  kubernetes = {
    config_path = "kubeconfig.yaml"
  }
}
