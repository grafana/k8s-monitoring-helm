<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# CloudWatch Metrics

This example demonstrates how to enable the CloudWatch Metrics feature to gather metrics from AWS CloudWatch and
deliver them to a metrics destination.

The exporter uses the AWS credentials available to the collector Pod, so the collector's ServiceAccount needs to be
annotated for IRSA, or associated with an EKS Pod Identity. The role needs `cloudwatch:GetMetricData`,
`cloudwatch:ListMetrics`, `tag:GetResources`, and the list or describe calls for the services being gathered.

The feature is assigned to a singleton collector, because the exporter runs in every replica of its collector and each
replica is billed for its own CloudWatch API calls.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: cloudwatch-metrics-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

cloudwatchMetrics:
  enabled: true
  collector: alloy-singleton
  instances:
    - name: production
      regions: [eu-central-1]
      discoveryJobs:
        - type: AWS/SQS
          searchTags:
            scrape: "true"
          metrics:
            - name: NumberOfMessagesSent
              statistics: [Sum]
            - name: ApproximateAgeOfOldestMessage
              statistics: [Maximum]
        - type: AWS/ELB
          metrics:
            - name: RequestCount
              statistics: [Sum]
              period: 1m

collectors:
  alloy-singleton:
    presets: [singleton]
```
<!-- textlint-enable terminology -->
