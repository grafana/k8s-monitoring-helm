# ArgoCD

This example shows how to deploy the Kubernetes Monitoring Helm chart as an Application from within ArgoCD. This defines
the application using ArgoCD's [Helm application spec](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/), which
does not install the Helm chart directly, but instead utilizes `helm template` to render the chart manifests and deploys
them to the cluster.

For a step-by-step Grafana Cloud guide built on top of these manifests, refer to
[Send Kubernetes metrics, logs, and events with Helm and Argo CD to Grafana Cloud](https://grafana.com/docs/grafana-cloud/monitor-infrastructure/kubernetes-monitoring/configuration/config-other-methods/argocd-config/).

Three variants are provided:

- [`k8s-monitoring-application.yaml`](./k8s-monitoring-application.yaml): a single-cluster `Application` with
  credentials embedded in `valuesObject`. Easiest to read; convenient for getting started.
- [`k8s-monitoring-application-external-secrets.yaml`](./k8s-monitoring-application-external-secrets.yaml): the same
  single-cluster `Application`, but credentials are read from a pre-existing Kubernetes `Secret` using the
  [external secrets pattern](../../auth/external-secrets). Endpoint URLs stay inline in the manifest; only credentials
  live in the Secret. Recommended for any environment where credentials should not live in the manifest checked into
  git.
- [`k8s-monitoring-applicationset.yaml`](./k8s-monitoring-applicationset.yaml): an `ApplicationSet` using the
  [cluster generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/) to
  fan the same configuration out to every Argo CD cluster carrying the `kubernetes-monitoring: enabled` label.
  Combine with the external-secrets variant when each managed cluster has its own credentials Secret.

## Setting `null` values

These examples use the `valuesObject` field to define Helm values inline within the Application manifest as YAML
object. If you need to remove a value that is set by default in the Helm chart, you will need to explicitly set it to
`null`. However, this currently [does not work](https://github.com/argoproj/argo-cd/issues/16312) when using
`valuesObject`, so instead utilize the multiline string `values` field to define your Helm chart values. Note you
cannot combine both `valuesObject` and `values` in the same Application manifest, as the `valuesObject` field takes
precedence and the result will not be a merged object.

## Application manifest

```yaml
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: k8s-monitoring-application
  namespace: argocd
operation:
  sync:
    syncStrategy:
      hook: {}
spec:
  project: default
  syncPolicy:
    automated:
      selfHeal: true
      enabled: true
    syncOptions:
      - Retry=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 1m
  destination:
    server: "https://kubernetes.default.svc"
    namespace: default
  source:
    repoURL: https://github.com/grafana/k8s-monitoring-helm.git
    path: charts/k8s-monitoring
    targetRevision: "main"
    helm:
      releaseName: k8smon
      valuesObject:
        cluster:
          name: argocd-deployment-test
        destinations:
          localPrometheus:
            type: prometheus
            url: http://prometheus-server.prometheus.svc:9090/api/v1/write
            auth:
              type: basic
              username: promuser
              password: prometheuspassword
          localLoki:
            type: loki
            url: http://loki.loki.svc:3100/loki/api/v1/push
            tenantId: "1"
            auth:
              type: basic
              username: loki
              password: lokipassword
        clusterMetrics:
          enabled: true
          collector: alloy-metrics

        costMetrics:
          enabled: true
          collector: alloy-metrics

        hostMetrics:
          enabled: true
          collector: alloy-metrics
          linuxHosts:
            enabled: true
          windowsHosts:
            enabled: true
          energyMetrics:
            enabled: true

        clusterEvents:
          enabled: true
          collector: alloy-singleton

        podLogsViaLoki:
          enabled: true
          collector: alloy-logs
          structuredMetadata:
            pod: ""

        collectors:
          alloy-metrics:
            presets: [clustered, statefulset]
          alloy-logs:
            presets: [filesystem-log-reader, daemonset]
          alloy-singleton:
            presets: [singleton]

        collectorCommon:
          alloy:
            annotations:
              argocd.argoproj.io/sync-wave: "1"

        telemetryServices:
          kube-state-metrics:
            deploy: true
          node-exporter:
            deploy: true
          windows-exporter:
            deploy: true
          kepler:
            deploy: true
          opencost:
            deploy: true
            metricsSource: localPrometheus
            annotations:
              argocd.argoproj.io/sync-wave: "1"
            opencost:
              exporter:
                defaultClusterId: argocd-deployment-test
              prometheus:
                existingSecretName: localprometheus-k8smon-k8s-monitoring
                external:
                  url: http://prometheus-server.prometheus.svc:9090
```
