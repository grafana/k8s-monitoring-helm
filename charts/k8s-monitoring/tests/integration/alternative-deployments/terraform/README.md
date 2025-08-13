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
```

### `grafana-k8s-monitoring.tf`

This file defines how to deploy the Helm chart as well as how to translate the Terraform vars into Helm chart values.

```terraform
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
```

### `vars.tf`

This file provides the variables and their values that'll be send to the Helm chart during deployment.

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
```

## Deploying

Run `terraform init` and `terraform apply` to deploy this Helm chart to your cluster.

```shell
$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/helm versions matching "3.0.2"...
- Installing hashicorp/helm v3.0.2...
- Installed hashicorp/helm v3.0.2 (signed by HashiCorp)

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
