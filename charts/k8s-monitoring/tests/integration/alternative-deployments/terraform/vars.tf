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
  default = "http://prometheus-server.prometheus.svc:9090/api/v1/write"
}

variable "prometheus-username" {
  type    = string
  default = "promuser"
}

variable "prometheus-password" {
  type    = string
  default = "prometheuspassword"
}

variable "loki-url" {
  type    = string
  default = "http://loki.loki.svc:3100/loki/api/v1/push"
}

variable "loki-username" {
  type    = string
  default = "loki"
}

variable "loki-password" {
  type    = string
  default = "lokipassword"
}

variable "loki-tenantid" {
  type    = string
  default = "1"
}
