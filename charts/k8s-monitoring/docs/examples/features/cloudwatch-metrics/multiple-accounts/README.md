<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# CloudWatch Metrics from several AWS accounts

This example demonstrates how to gather AWS CloudWatch metrics from more than one AWS account, and how to run several
exporter instances side by side.

The first instance lists two `roles`, so every job in it is gathered once per role. The collector's own credentials only
need permission to assume those roles.

The second instance shows why you would use more than one instance: it calls STS in a different region, gathers a custom
CloudWatch namespace, and applies its own metric tuning. It also enables `decoupledScraping`, which gathers metrics on a
background timer so that the CloudWatch API call rate no longer follows the scrape interval. That background poller runs
in every replica of the collector and is not sharded by clustering, so the feature must stay on a single-replica
collector.

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
    # Gathers the same jobs from two AWS accounts by assuming a role in each one.
    - name: all-accounts
      regions: [eu-central-1, eu-west-1]
      roles:
        - roleArn: arn:aws:iam::111111111111:role/CloudWatchReadOnly
        - roleArn: arn:aws:iam::222222222222:role/CloudWatchReadOnly
          externalId: shared-secret
      discoveryJobs:
        - type: AWS/SQS
          metrics:
            - name: NumberOfMessagesSent
              statistics: [Sum]

    # A second instance keeps a different STS region, and its own metric tuning, separate from the first.
    - name: us-audit
      stsRegion: us-east-1
      regions: [us-east-1]
      # Gather in the background so that the CloudWatch API call rate does not follow the scrape interval.
      decoupledScraping:
        enabled: true
        scrapeInterval: 15m
      customNamespaceJobs:
        - name: audit_pipeline
          namespace: MyCompany/Audit
          metrics:
            - name: RecordsProcessed
              statistics: [Sum]
      metrics:
        tuning:
          excludeMetrics: [aws_mycompany_audit_recordsprocessed_average]

collectors:
  alloy-singleton:
    presets: [singleton]
```
<!-- textlint-enable terminology -->
