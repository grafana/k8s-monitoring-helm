Describe 'Invalid logs configurations'
  Describe 'Using a daemonset with API log gathering and no clustering'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/invalid-logs-config-daemonset-and-api_values.yaml"
      The status should be failure
      The error should include 'Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "api" and the Grafana Alloy for Logs is a Daemonset, you must enable clustering. Otherwise, log files may be duplicated!
Please set:
alloy-logs:
  alloy:
    clustering:
      enabled: true'
    End
  End

  Describe 'Using volume log gathering and clustering'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/invalid-logs-config-volumes-and-clustering-values.yaml"
      The status should be failure
      The error should include 'Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "volumes", Grafana Alloy for Logs should not utilize clustering. Otherwise, performance will suffer!
Please set:
alloy-logs:
  alloy:
    clustering:
      enabled: false'
    End
  End

  Describe 'Using multiple replicas with API log gathering and no clustering'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/invalid-logs-config-multiple-replicas-and-api_values.yaml"
      The status should be failure
      The error should include 'Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "api" and the Grafana Alloy for Logs has multiple replicas, you must enable clustering. Otherwise, log files will be duplicated!
Please set:
alloy-logs:
  alloy:
    clustering:
      enabled: true'
    End
  End

  Describe 'Using non-daemonset with volume log gathering'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/invalid-logs-config-non-daemonset-and-volumes_values.yaml"
      The status should be failure
      The error should include 'Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "volumes", Grafana Alloy for Logs must be a Daemonset. Otherwise, logs will be missing!
Please set:
logs:
  pod_logs:
    gatherMethod: api
  or
alloy-logs:
  controller:
    type: daemonset'
    End
  End

  Describe 'Using non-daemonset with journal log gathering'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/invalid-logs-config-non-daemonset-and-journal-logs_values.yaml"
      The status should be failure
      The error should include 'Invalid configuration for gathering journal logs! Grafana Alloy for Logs must be a Daemonset. Otherwise, journal logs will be missing!
Please set:
alloy-logs:
  controller:
    type: daemonset'
    End
  End
End
