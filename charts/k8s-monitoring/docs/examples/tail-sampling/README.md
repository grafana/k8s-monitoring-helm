<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Tail Sampling

This example shows how to configure tail sampling for traces using the k8s-monitoring Helm chart. Tail sampling is a technique that allows you to make sampling decisions after all spans in a trace
have been collected, rather than making the decision at the beginning of the trace.

## What is Tail Sampling?

Unlike head sampling (where the sampling decision is made when the trace starts), tail sampling collects all spans for a trace and then makes a sampling decision based on the complete trace information. This allows for more sophisticated sampling strategies that can:

-   Keep all traces with errors regardless of their duration
-   Sample traces based on their total latency
-   Make decisions based on specific attributes present anywhere in the trace
-   Apply complex logic combining multiple conditions

## Configuration

This example configures tail sampling for traces sent to a Tempo/otlp destination. The configuration includes various sampling policies that demonstrate different tail sampling strategies.

In this example:

-   The tail sampling processor is configured with decision timing and caching parameters
-   Multiple sampling policies are defined including status code, latency, probabilistic, and attribute-based policies
-   The policies work together to ensure important traces are kept while reducing overall trace volume

The tail sampling configuration allows you to optimize trace storage costs while maintaining observability for critical traces.

```yaml
  - name: tempo
    type: otlp
    url: http://tempo.tempo.svc
    metrics:
      enabled: false
    logs:
      enabled: false
    traces:
      enabled: true
    processors:
      tailSampling:
        enabled: true
        decisionWait: 5s
        numTraces: 100
        expectedNewTracesPerSec: 10
        decisionCache:
          sampledCacheSize: 1000
          nonSampledCacheSize: 10000
        policies:
          # Keep errors and unset status codes
          - name: "keep-errors"
            type: "status_code"
            status_codes: ["ERROR", "UNSET"]
          # Sample slow traces
          - name: "sample-slow-traces"
            type: "latency"
            threshold_ms: 5000
          # Sample 15% of traces
          - name: "sample-15pct-traces"
            type: "probabilistic"
            sampling_percentage: 15
          # Sample traces with http.status_code between 399 and 599 and status code ERROR or UNSET
          - name: "and-policy"
            type: and
            and:
              and_sub_policy:
                - name: "keep-all-error-codes"
                  type: numeric_attribute
                  key: http.status_code
                  min_value: 399
                  max_value: 599
                - name: "keep-all-errors"
                  type: "status_code"
                  values:
                    - ERROR
                    - UNSET
```

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: tail-sampling
destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
  - name: loki
    type: loki
    url: http://loki.loki.svc:3100/api/push
  - name: tempo
    type: otlp
    url: http://tempo.tempo.svc
    metrics:
      enabled: false
    logs:
      enabled: false
    traces:
      enabled: true
    processors:
      tailSampling:
        enabled: true
        decisionWait: 5s
        numTraces: 100
        expectedNewTracesPerSec: 10
        decisionCache:
          sampledCacheSize: 1000
          nonSampledCacheSize: 10000
        policies:
          # Keep errors and unset status codes
          - name: "keep-errors"
            type: "status_code"
            status_codes: ["ERROR", "UNSET"]
          # Sample slow traces
          - name: "sample-slow-traces"
            type: "latency"
            threshold_ms: 5000
          # Sample 15% of traces
          - name: "sample-15pct-traces"
            type: "probabilistic"
            sampling_percentage: 15
          # Sample traces with http.status_code between 399 and 599 and status code ERROR or UNSET
          - name: "and-policy"
            type: and
            and:
              and_sub_policy:
                - name: "keep-all-error-codes"
                  type: numeric_attribute
                  key: http.status_code
                  min_value: 399
                  max_value: 599
                - name: "keep-all-errors"
                  type: "status_code"
                  status_codes:
                    - ERROR
                    - UNSET
clusterMetrics:
  enabled: true

podLogs:
  enabled: true
applicationObservability:
  enabled: true
  receivers:
    otlp:
      http:
        enabled: true
        port: 4318
  connectors:
    grafanaCloudMetrics:
      enabled: true

alloy-metrics:
  enabled: true

alloy-logs:
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
