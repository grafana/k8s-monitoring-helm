# ArgoCD

This example shows how to deploy the Kubernetes Monitoring Helm chart as an Application from within ArgoCD. This defines
the application using ArgoCD's [Helm application spec](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/), which
does not install the Helm chart directly, but instead utilizes `helm template` to render the chart manifests and deploys
them to the cluster.

## Setting `null` values

This example uses the `valuesObject` field to define Helm values inline within the Application manifest as YAML object.
If you need to remove a value that is set by default in the Helm chart, you will need to explicitly set it to `null`.
However, this currently [does not work](https://github.com/argoproj/argo-cd/issues/16312) when using `valuesObject`, so
instead utilize the multiline string `values` field to define your Helm chart values. Note you cannot combine both
`valuesObject` and `values` in the same Application manifest, as the `valuesObject` field takes precedence and the
result will not be a merged object.

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
          - name: localPrometheus
            type: prometheus
            url: http://prometheus-server.prometheus.svc:9090/api/v1/write
            auth:
              type: basic
              username: promuser
              password: prometheuspassword
          - name: localLoki
            type: loki
            url: http://loki.loki.svc:3100/loki/api/v1/push
            tenantId: "1"
            auth:
              type: basic
              username: loki
              password: lokipassword
        clusterMetrics:
          enabled: true
          kepler:
            enabled: true
          opencost:
            enabled: true
            annotations:
              argocd.argoproj.io/sync-wave: "1"
            metricsSource: localPrometheus
            opencost:
              exporter:
                defaultClusterId: argocd-deployment-test
              prometheus:
                existingSecretName: localprometheus-k8smon-k8s-monitoring
                external:
                  url: http://prometheus-server.prometheus.svc:9090
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
        collectorCommon:
          alloy:
            annotations:
              argocd.argoproj.io/sync-wave: "1"
```
