Describe 'Deprecation Warning Check'
  Describe 'Receivers in Traces'
    It 'prints a friendly error message'
      When call helm template k8smon ../charts/k8s-monitoring -f "spec/fixtures/deprecated-trace-receivers_values.yaml"
      The status should be failure
      The error should include 'As of k8s-monitoring Chart version 0.7, the ".traces.receivers" section has been moved to ".receivers".
Please update your values file and try again.
For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring#breaking-change-announcements'
    End
  End
End
