<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Profiles Receiver

This example demonstrates how to enable the Profiles Receiver feature to receive profiles from applicaations on your
Kubernetes cluster, process them according to defined rules, and then deliver them to Pyroscope.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: profiles-receiver-cluster

destinations:
  - name: pyroscope
    type: pyroscope
    url: http://pyroscope.pyroscope.svc:4040

profilesReceiver:
  enabled: true
  profilesProcessingRules: |
    // This creates a consistent hash value (0 or 1) for each unique combination of labels
    // Using multiple source labels provides better sampling distribution across your profiles
    rule {
      source_labels = ["env"]
      target_label = "__tmp_hash"
      action = "hashmod"
      modulus = 2
    }

    // This effectively samples ~50% of profile series
    // The same combination of source label values will always hash to the same number,
    // ensuring consistent sampling
    rule {
      source_labels = ["__tmp_hash"]
      action       = "drop"
      regex        = "^1$"
    }

alloy-receiver:
  enabled: true
```
<!-- textlint-enable terminology -->
