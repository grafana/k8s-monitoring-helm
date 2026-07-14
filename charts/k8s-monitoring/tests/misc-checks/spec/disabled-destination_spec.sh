Describe 'Disabled Destination Check'
  Describe 'Setting a destination to "disabled: true"'
    It 'does not include that destination'
      When call helm template test ../../ -f test-harness/disabled-destination-values.yaml --set destinations.secondMetricsService.disabled=true
      The status should be success
      The stdout should include '// Destination: metricsService (prometheus)'
      The stdout should not include '// Destination: secondMetricsService (prometheus)'
    End
  End
End
