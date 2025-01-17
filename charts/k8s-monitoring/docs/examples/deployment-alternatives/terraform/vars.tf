variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "cluster-name" {
  type    = string
  default = "terraform-test"
}

variable "prometheus-url" {
  type    = string
  default = "https://prometheus.example.com/api/v1/write"
}

variable "prometheus-username" {
  type    = string
  default = "12345"
}

variable "prometheus-password" {
  type    = string
  default = "It's a secret to everyone"
}

variable "loki-url" {
  type    = string
  default = "https://loki.example.com/loki/api/v1/push"
}

variable "loki-username" {
  type    = string
  default = "12345"
}

variable "loki-password" {
  type    = string
  default = "It's a secret to everyone"
}

variable "loki-tenantid" {
  type    = string
  default = "1"
}
