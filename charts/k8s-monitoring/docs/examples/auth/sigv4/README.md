<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# AWS Signature Version 4 Auth Example

This example shows how to configure a Prometheus destination using the AWS Signature Version 4 authentication method.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: sigv4-auth-example-cluster

destinations:
  - name: prometheus
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write
    auth:
      type: sigv4
      sigv4:
        region: ap-southeast-2
        accessKey: my-access-key
        secretKey: my-secret-key
  - name: otlp-endpoint
    type: otlp
    url: http://otlp-endpoing.example.com:4317
    auth:
      type: sigv4
      sigv4:
        region: ap-southeast-2
        assumeRole:
          arn: arn:aws:iam::123456789012:role/aws-service-role/access
          stsRegion: ap-southeast-2
          sessionName: example-session

clusterMetrics:
  enabled: true

alloy-metrics:
  enabled: true
```
<!-- textlint-enable terminology -->
