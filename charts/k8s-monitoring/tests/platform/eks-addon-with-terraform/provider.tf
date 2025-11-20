terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.21.0"
    }
  }
}

provider "aws" {
  access_key                  = var.aws-access-key
  region                      = "ap-northeast-2"
  secret_key                  = var.aws-secret-key
}
