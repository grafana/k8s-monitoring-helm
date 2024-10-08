<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# AWS Signature Version 4 Auth Example

This example shows how to configure a Prometheus destination using the AWS Signature Version 4 authentication method.

## Values

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

clusterMetrics:
  enabled: true

alloy-metrics:
  enabled: true
```
