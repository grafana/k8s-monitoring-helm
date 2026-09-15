<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Zero-code SDK injection with Beyla

This example wires up the full zero-code SDK injection pipeline:

1. `telemetryServices.sdkInjector` deploys the Grafana Kubernetes Injection Controller (a mutating admission webhook).
2. The `autoInstrumentation` feature deploys Grafana Beyla in SDK Injector mode — it discovers the workloads to
   instrument (here, everything in the `demo` namespace) and writes the injection ConfigMaps that the controller
   consumes. `beyla.injector.enabled` grants Beyla the RBAC to write those ConfigMaps, and
   `telemetryServices.sdkInjector.allowedConfigMapWriters` allows Beyla's service account to do so.
3. When a matching Pod starts, the controller's webhook mutates it to mount the Grafana OpenTelemetry SDK (via an
   `ImageVolumeSource` on Kubernetes 1.35+, or an init container on older clusters) and sets the `OTEL_*` environment
   variables. No application code or container image changes are required. Beyla restarts already-running eligible
   workloads for you.
4. The injected SDK sends its telemetry to the Application Observability OTLP receiver, which forwards it to your
   destinations.

The `annotationAutodiscovery` feature scrapes the controller's own metrics endpoint, so you can observe injection
results — for example the `beyla_injection_pods` metric, which reports each workload the controller has instrumented.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: sdk-injector-injection

destinations:
  localPrometheus:
    type: prometheus
    url: http://prometheus-server.prometheus.svc:9090/api/v1/write
  localLoki:
    type: loki
    url: http://loki.loki.svc:3100/loki/api/v1/push
    tenantId: "1"
    auth:
      type: basic
      username: loki
      password: lokipassword
  localTempo:
    type: otlp
    url: tempo.tempo.svc:4317
    tls:
      insecure: true
      insecureSkipVerify: true
    metrics: {enabled: false}
    logs: {enabled: false}
    traces: {enabled: true}

# Scrape the SDK Injector controller's metrics endpoint so we can observe injection results (e.g. the
# beyla_injection_pods metric, which reports each workload the controller has instrumented).
annotationAutodiscovery:
  enabled: true
  collector: alloy

# The Application Observability feature opens an OTLP receiver. The SDKs injected into application Pods send their
# telemetry here, and Beyla auto-wires the injected OTEL_EXPORTER_OTLP_ENDPOINT to this receiver.
applicationObservability:
  enabled: true
  collector: alloy
  receivers:
    otlp:
      grpc:
        enabled: true

# The auto-instrumentation feature deploys Grafana Beyla. In addition to its eBPF instrumentation, Beyla runs in SDK
# Injector mode here: it discovers workloads and writes the injection ConfigMaps that the SDK Injector controller
# consumes. `beyla.injector.enabled` grants Beyla the namespaced RBAC to write those ConfigMaps.
autoInstrumentation:
  enabled: true
  collector: alloy
  beyla:
    injector:
      enabled: true
    config:
      data:
        injector:
          # Instrument workloads in the `demo` namespace with the Grafana OpenTelemetry SDK distributions.
          instrument:
            - k8s_namespace: demo
          image_version: "0.0.13"
          # Delegate the actual Pod mutation to the SDK Injector controller deployed by telemetryServices.sdkInjector.
          webhook:
            external_deployment_name: default/k8smon-k8s-injection-controller

telemetryServices:
  # Deploy the SDK Injector (Grafana Kubernetes Injection Controller). Allow Beyla's service account to write the
  # annotated injection ConfigMaps.
  sdkInjector:
    deploy: true
    allowedConfigMapWriters: system:serviceaccount:$(POD_NAMESPACE):k8smon-beyla
    # The controller advertises its metrics endpoint with prometheus.io annotations by default. Add this chart's
    # native k8s.grafana.com/* annotations so Annotation Autodiscovery discovers and scrapes it on port 8080.
    metrics:
      annotations:
        k8s.grafana.com/scrape: "true"
        k8s.grafana.com/metrics.portNumber: "8080"

collectors:
  alloy:
    presets: [clustered, statefulset]
```
<!-- textlint-enable terminology -->
