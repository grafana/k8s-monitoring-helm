Describe 'Deprecation Warning Check'
  Describe 'Using prometheus.remote_write.grafana_cloud_prometheus'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/deprecated-metrics-component_values.yaml"
      The status should be failure
      The error should include 'As of k8s-monitoring Chart version 0.3, the component "prometheus.remote_write.grafana_cloud_prometheus" has been renamed.
Please change your configurations to direct metric data to the "prometheus.relabel.metrics_service" component instead.
For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring-v1#breaking-change-announcements'
    End
  End

  Describe 'Receivers in Traces'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/deprecated-trace-receivers_values.yaml"
      The status should be failure
      The error should include 'As of k8s-monitoring Chart version 0.7, the ".traces.receivers" section has been moved to ".receivers".
Please update your values file and try again.
For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring-v1#breaking-change-announcements'
    End
  End

  Describe 'Using an allowList and not metricsTuning'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/deprecated-allow-list_values.yaml"
      The status should be failure
      The error should include 'As of k8s-monitoring Chart version 0.9, metric sources no longer utilize ".allowList".
Controlling the amount of metrics returned can be done with the ".metricsTuning" section.
Please update your values file and try again.
For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring-v1#breaking-change-announcements'
    End
  End

  Describe 'Using loki.write.grafana_cloud_loki'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/deprecated-logs-component_values.yaml"
      The status should be failure
      The error should include 'As of k8s-monitoring Chart version 0.12, the component "loki.write.grafana_cloud_loki" has been renamed.
Please change your configurations to direct log data to the "loki.process.logs_service" component instead.
For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring-v1#breaking-change-announcements'
    End
  End

  Describe 'Grafana Agent modification in values file'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/deprecated-grafana_agent-values.yaml"
      The status should be failure
      The error should include 'As of k8s-monitoring Chart version 1.0, Grafana Agent has been replaced with Grafana Alloy.
These sections in your values file will need to be renamed:
  grafana-agent          --> alloy
  grafana-agent-events   --> alloy-events
  grafana-agent-logs     --> alloy-logs
  grafana-agent-profiles --> alloy-profiles
  metrics.agent          --> metrics.alloy

For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring-v1#breaking-change-announcements'
    End
  End

  Describe 'Agent metric modification in values file'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/deprecated-agent_metrics-values.yaml"
      The status should be failure
      The error should include 'As of k8s-monitoring Chart version 1.0, Grafana Agent has been replaced with Grafana Alloy.
These sections in your values file will need to be renamed:
  grafana-agent          --> alloy
  grafana-agent-events   --> alloy-events
  grafana-agent-logs     --> alloy-logs
  grafana-agent-profiles --> alloy-profiles
  metrics.agent          --> metrics.alloy

For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring-v1#breaking-change-announcements'
    End
  End

  Describe 'Using older OpenCost secret_name in values file'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/deprecated-opencost-secret_values.yaml"
      The status should be failure
      The error should include 'As of k8s-monitoring Chart version 1.0.1, OpenCost changed how to reference an external secret.
Please rename:
opencost:
  opencost:
    prometheus:
      secret_name: prometheus-k8s-monitoring
To:
opencost:
  opencost:
    prometheus:
      existingSecretName: prometheus-k8s-monitoring

For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring-v1#breaking-change-announcements'
    End
  End
End
