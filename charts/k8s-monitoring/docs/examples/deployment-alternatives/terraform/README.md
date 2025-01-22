# Terraform Deployment

Some may want to use [Terraform](https://www.terraform.io/) to deploy the Kubernetes Monitoring Helm chart. This is
accomplished with the use of
the [Helm provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs), and
its [helm_release](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release#create_namespace)
resource. To use this, adapt the provider to connect to your own Kubernetes cluster and modify the `vars.tf` file to the
specific values for your deployment. If you want to provide additional values, follow the same pattern or look at
the [helm_release documentation](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)
for more options.

## Files

This example shows the various files used by Terraform to define and deploy the Kubernetes Monitoring Helm chart.

### `provider.tf`

This file shows the inclusion and instantiation of the Helm provider.

```terraform
terraform {
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
```

### `grafana-k8s-monitoring.tf`

This file defines how to deploy the Helm chart as well as how to translate the Terraform vars into Helm chart values.
It also embeds a limited version of the Helm chart's values file as a string for chart configuration that does not
contain credentials.

```terraform
resource "helm_release" "grafana-k8s-monitoring" {
  name             = "grafana-k8s-monitoring"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "k8s-monitoring"
  namespace        = var.namespace
  create_namespace = true
  atomic           = true
  values = [<<-EOT
      destinations:
        - name: metrics-destination
          type: prometheus
          auth:
            type: basic
        - name: logs-destination
          type: loki
          auth:
            type: basic

      clusterMetrics:
        enabled: true
      clusterEvents:
        enabled: true
      podLogs:
        enabled: true

      alloy-metrics:
        enabled: true
      alloy-singleton:
        enabled: true
      alloy-logs:
        enabled: true
      EOT
  ]

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
```

### `vars.tf`

This file provides the variables and their values that'll be used during deployment.

```terraform
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
```

## Deploying

Run `terraform init` and `terraform apply` to deploy this Helm chart to your cluster.

```shell
$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/helm versions matching "2.17.0"...
- Installing hashicorp/helm v2.17.0...
- Installed hashicorp/helm v2.17.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # helm_release.grafana-k8s-monitoring will be created
  + resource "helm_release" "grafana-k8s-monitoring" {
    ...
  }
Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

helm_release.grafana-k8s-monitoring: Creating...
helm_release.grafana-k8s-monitoring: Still creating... [10s elapsed]
helm_release.grafana-k8s-monitoring: Still creating... [20s elapsed]
vhelm_release.grafana-k8s-monitoring: Creation complete after 27s [id=grafana-k8s-monitoring]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
$
```
