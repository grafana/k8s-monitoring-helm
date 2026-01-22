<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# OTLP Attributes Processor Include/Exclude Example

This example demonstrates how to use include and exclude blocks with the OTLP Attributes Processor to selectively
filter and process telemetry data based on service names, span names, log severity, and other criteria.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: otelcol-attributes-example

destinations:
  - name: otlp_endpoint
    type: otlp
    url: https://otlp.example.com
    auth:
      type: basic
      username: "user"
      password: "pass"
    processors:
      attributes:
        # Include block: Filter by service.name resource attribute (works for all signal types)
        include:
          matchType: "strict"
          resources:
            - key: "service.name"
              value: "api-gateway"
            - key: "service.name"
              value: "payment-service"
            - key: "service.name"
              value: "user-service"
        # Actions to apply to the filtered telemetry
        actions:
          # Extract deployment and namespace from http.url
          - key: "http.url"
            action: "extract"
            pattern: '(?:https?://)?(?P<deployment>[a-z][\w-]+)\.(?P<namespace>[a-z][\w-]+)(?:\..+){2,}/.*'
          # Extract namespace and deployment from http.target
          - key: "http.target"
            action: "extract"
            pattern: '(?:https?://)?/(?P<namespace>[a-z][\w-]+)/(?P<deployment>[a-z][\w-]+)/.*'
          # Add a custom attribute
          - key: "environment"
            action: "insert"
            value: "production"

# Enable application observability to generate traces for the examples
applicationObservability:
  enabled: true
  receivers:
    otlp:
      grpc:
        enabled: true

# Enable metrics collection
clusterMetrics:
  enabled: true

# Enable log collection
podLogs:
  enabled: true

# Enable alloy instances
alloy-metrics:
  enabled: true

alloy-logs:
  enabled: true

alloy-receiver:
  enabled: true
```
<!-- textlint-enable terminology -->
