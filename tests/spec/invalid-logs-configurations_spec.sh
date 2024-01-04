Describe 'Invalid logs configurations'
  Describe 'Using a daemonset with API log gathering and no clustering'
    It 'prints a friendly error message'
      When call helm template k8smon ../charts/k8s-monitoring -f "spec/fixtures/invalid-logs-config-daemonset-and-api_values.yaml"
      The status should be failure
      The error should include 'Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "api" and the Grafana Agent for Logs is a Daemonset, you must enable clustering. Otherwise, log files may be duplicated!
Please set:
grafana-agent-logs:
  agent:
    clustering:
      enabled: true'
    End
  End

  Describe 'Using multiple replicas with API log gathering and no clustering'
    It 'prints a friendly error message'
      When call helm template k8smon ../charts/k8s-monitoring -f "spec/fixtures/invalid-logs-config-multiple-replicas-and-api_values.yaml"
      The status should be failure
      The error should include 'Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "api" and the Grafana Agent for Logs has multiple replicas, you must enable clustering. Otherwise, log files will be duplicated!
Please set:
grafana-agent-logs:
  agent:
    clustering:
      enabled: true'
    End
  End

  Describe 'Using non-daemonset with volume log gathering'
    It 'prints a friendly error message'
      When call helm template k8smon ../charts/k8s-monitoring -f "spec/fixtures/invalid-logs-config-non-daemonset-and-volumes_values.yaml"
      The status should be failure
      The error should include 'Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "volumes", Grafana Agent for Logs must be a Daemonset. Otherwise, logs will be missing!
Please set:
logs:
  pod_logs:
    gatherMethod: api
  or
grafana-agent-logs:
  controller:
    type: daemonset'
    End
  End
End
