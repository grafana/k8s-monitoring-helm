<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Application Observability with tail sampling

This example shows how to enable the Application Observability feature with tail sampling
using the [grafana-sampling](https://github.com/grafana/helm-charts/tree/main/charts/grafana-sampling) chart and Grafana Cloud.

The grafana/grafana-sampling chart can be installed alongside the k8s-monitoring-helm chart to provide a flexible OTLP tail sampling pipeline. Once the
sampling chart is installed, then the tail sampling deployment should be added to the k8s-monitoring-helm chart as an OTLP destination for traces. Applications should continue to send their telemetry to the alloy-receiver deployed by the k8s-monitoring-helm chart, which will then forward traces through the sampling layers.

```mermaid
flowchart TD
    subgraph App["Application(s)"]
        A[OTLP Exporter]
    end

    subgraph KM["k8s-monitoring"]
        B[Alloy Receiver]
    end

    subgraph Destinations
        C1[Grafana Cloud<br/>Metrics]
        C2[Grafana Cloud<br/>Logs]
    end

    subgraph Sampler["grafana-sampling"]
        D["tail-sampler Deployment"]
        E[tail-sampler StatefulSet<br/>]
    end

    subgraph GCloud["Destinations"]
        F[Grafana Cloud Traces]
        G[Grafana Cloud Metrics]
    end

    %% Application to Alloy Receiver
    A -->|OTLP<br/>metrics/logs/traces| B

    %% Alloy Receiver to Grafana Cloud
    B -->|Metrics| C1
    B -->|Logs| C2

    %% Alloy Receiver to Tail Sampler
    B -->|Traces| D
    D -->|Load Balanced| E

    %% Tail Sampler to Grafana Cloud
    E -->|Traces| F
    E -->|Metrics| G
```

For more information, see the [Application Observability feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-application-observability).

## grafana-sampling chart installation

### 1. Create secret to use with the sampling helm chart

This secret stores credentials needed for remote write access to your Grafana Cloud metrics and traces.

```bash
# grafana cloud api token with write scopes for metrics and traces
GRAFANA_CLOUD_API_KEY="***"

# update username and remote write url to match your grafana cloud stack
GRAFANA_CLOUD_PROMETHEUS_USERNAME="1234"
GRAFANA_CLOUD_PROMETHEUS_URL="https://prometheus-prod-13-prod-us-east-0.grafana.net/api/prom/push"

# update username and tempo endpoint to match your grafana cloud stack
GRAFANA_CLOUD_TEMPO_USERNAME="4567"
GRAFANA_CLOUD_TEMPO_ENDPOINT=tempo-prod-04-prod-us-east-0.grafana.net:443

kubectl create secret --namespace=default generic sampling-credentials \
  --from-literal=GRAFANA_CLOUD_API_KEY="$GRAFANA_CLOUD_API_KEY" \
  --from-literal=GRAFANA_CLOUD_PROMETHEUS_USERNAME="$GRAFANA_CLOUD_PROMETHEUS_USERNAME" \
  --from-literal=GRAFANA_CLOUD_PROMETHEUS_URL="$GRAFANA_CLOUD_PROMETHEUS_URL" \
  --from-literal=GRAFANA_CLOUD_TEMPO_USERNAME="$GRAFANA_CLOUD_TEMPO_USERNAME" \
  --from-literal=GRAFANA_CLOUD_TEMPO_ENDPOINT="$GRAFANA_CLOUD_TEMPO_ENDPOINT" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 2. Install the sampling chart

```bash
helm install tail-sampler grafana/grafana-sampling --values - <<EOF
metricsGeneration:
  legacy: false
alloy-deployment:
  alloy:
    controller:
      replicas: 2
    resources:
      requests:
        cpu: "500m"
        memory: "1Gi"
      limits:
        cpu: "1"
        memory: "2Gi"
alloy-statefulset:
  alloy:
    controller:
      replicas: 3
    resources:
     requests:
       cpu: "500m"
       memory: "1Gi"
     limits:
       cpu: "1"
       memory: "2Gi"
    extraEnv:
      - name: GRAFANA_CLOUD_API_KEY
        valueFrom:
          secretKeyRef:
            name: sampling-credentials
            key: GRAFANA_CLOUD_API_KEY
      - name: GRAFANA_CLOUD_PROMETHEUS_USERNAME
        valueFrom:
          secretKeyRef:
            name: sampling-credentials
            key: GRAFANA_CLOUD_PROMETHEUS_USERNAME
      - name: GRAFANA_CLOUD_TEMPO_USERNAME
        valueFrom:
          secretKeyRef:
            name: sampling-credentials
            key: GRAFANA_CLOUD_TEMPO_USERNAME
      - name: GRAFANA_CLOUD_PROMETHEUS_URL
        valueFrom:
          secretKeyRef:
            name: sampling-credentials
            key: GRAFANA_CLOUD_PROMETHEUS_URL
      - name: GRAFANA_CLOUD_TEMPO_ENDPOINT
        valueFrom:
          secretKeyRef:
            name: sampling-credentials
            key: GRAFANA_CLOUD_TEMPO_ENDPOINT
      - name: POD_UID
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: metadata.uid
EOF
```

## k8s-monitoring-helm chart configuration

Install or upgrade the `k8s-monitoring` chart with an OTLP destination configured to send traces to the `tail-sampler-deployment` service.

```bash
helm upgrade --install k8s-monitoring grafana/k8s-monitoring \
  --namespace default \
  --values values.yaml
```

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: applications-cluster

destinations:
  - name: otlp-gateway
    type: otlp
    url: http://otlp-gateway.example.com
    metrics: {enabled: true}
    logs: {enabled: true}
    traces: {enabled: false}  # Disable traces in other destinations as all traces should be sent to the tail-sampler

  - name: tail-sampler
    type: otlp
    url: tail-sampler-deployment.default.svc.cluster.local:4317  # Update if using a different namespace or deployment name
    protocol: grpc
    tls:
      insecure: true
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

applicationObservability:
  enabled: true
  receivers:
    otlp:
      http:
        enabled: true

alloy-receiver:
  enabled: true
  alloy:
    extraPorts:
      - name: otlp-http
        port: 4318
        targetPort: 4318
        protocol: TCP
```
<!-- textlint-enable terminology -->
