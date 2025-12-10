<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
Using include and exclude blocks with the OTLP Attributes Processor to selectively filter and 
process telemetry data based on service names, span names, log severity, and other criteria.
## Values

<!-- textlint-disable terminology -->
```yaml
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
        # Include block: Only process traces from specific services
        include:
          matchType: "strict"
          services:
            - "api-gateway"
            - "payment-service"
            - "user-service"
        # Actions to apply to the filtered services
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
