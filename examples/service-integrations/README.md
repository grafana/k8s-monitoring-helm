# Service Integrations

This example shows how to augment your Kubernetes Monitoring deployment to gather telemetry data from 3rd party services.

In this example, there are two styles of integrations that are made possible:
* Automatic discovery via Kubernetes annotations
* Direct integration via Agent modules

## Cert Manager

Cert Manager is installed via its [Helm chart](https://cert-manager.io/docs/installation/helm/), and by using the
following values file, the Cert Manager Service will be annotated in such a way that it will be automatically discovered
by the Grafana Agent and scraped for metrics.

```yaml
installCRDs: true
serviceAnnotations:
  k8s.grafana.com/scrape: "true"
  k8s.grafana.com/job: "integrations/cert-manager"
```

## MySQL

Scraping the metrics from a MySQL database requires a different tactic, since it requires a username and password, and
cannot be determined by annotations alone. Instead, we create [a ConfigMap](./mysql-config.yaml) with custom Agent configuration, and then tell
the Agent to load that config.

## Kubernetes Monitoring

This is the values file for Kubernetes Monitoring, and it only differs from the default by using the `.extraConfig` and
`.logs.extraConfig` sections to load the configuration stored in the MySQL ConfigMap. Also, additional tests to the
`helm test` command will verify that telemetry data from the two services are discovered, scraped, and stored properly.

Note that no reference to the Cert Manager service is stored here, because it is discovered and scraped automatically.

```yaml
cluster:
  name: service-integrations-test

externalServices:
  prometheus:
    host: https://prometheus.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"
  loki:
    host: https://loki.example.com
    basicAuth:
      username: 12345
      password: "It's a secret to everyone"

extraConfig: |
  remote.kubernetes.configmap "mysql_config" {
    name = "mysql-monitoring"
    namespace = "mysql"
  }

  module.string "mysql_metrics" {
    content = remote.kubernetes.configmap.mysql_config.data["metrics.river"]

    arguments {
      host = "mysql.mysql.svc.cluster.local"
      instance = "primary"
      namespace = "mysql"
      secret_name = "mysql"
      username = "root"
      password_key = "mysql-root-password"
      all_services = discovery.kubernetes.services.targets
      metrics_destination = prometheus.relabel.metrics_service.receiver
    }
  }

logs:
  extraConfig: |
    remote.kubernetes.configmap "mysql_config" {
      name = "mysql-monitoring"
      namespace = "mysql"
    }

    module.string "mysql_logs" {
      content = remote.kubernetes.configmap.mysql_config.data["logs.river"]

      arguments {
        instance = "primary"
        all_pods = discovery.relabel.pod_logs.output
        logs_destination = loki.write.grafana_cloud_loki.receiver
      }
    }

test:
  extraQueries:
    # Check for CertManager metrics
    - query: "certmanager_clock_time_seconds{cluster=\"ci-integrations-cluster\"}"
      type: promql
    # Check for MySQL metrics
    - query: "mysqld_exporter_build_info{cluster=\"ci-integrations-cluster\"}"
      type: promql
    # Check for MySQL logs
    - query: "{cluster=\"ci-integrations-cluster\", job=\"integrations/mysql\"}"
      type: logql
```
