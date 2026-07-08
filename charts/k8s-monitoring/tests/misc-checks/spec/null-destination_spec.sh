Describe 'Null Destination Check'
  Describe 'Setting a destination to "null"'
    It 'does not include that destination'
      When call helm template test ../../ -f test-harness/null-destination-values.yaml --set destinations.secondMetricsService=null
      The status should be success
      The stdout should include '// Destination: metricsService (prometheus)'
      The stdout should not include '// Destination: secondMetricsService (prometheus)'
    End
  End
End
