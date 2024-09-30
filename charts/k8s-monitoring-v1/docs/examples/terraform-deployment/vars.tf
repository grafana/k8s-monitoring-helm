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
  default = "https://prometheus.example.com"
}

variable "prometheus-username" {
  type    = number
  default = 12345
}

variable "prometheus-password" {
  type    = string
  default = "It's a secret to everyone"
}

variable "loki-url" {
  type    = string
  default = "https://loki.example.com"
}

variable "loki-username" {
  type    = number
  default = 12345
}

variable "loki-password" {
  type    = string
  default = "It's a secret to everyone"
}

variable "tempo-url" {
  type    = string
  default = "https://tempo.example.com"
}

variable "tempo-username" {
  type    = number
  default = 12345
}

variable "tempo-password" {
  type    = string
  default = "It's a secret to everyone"
}
