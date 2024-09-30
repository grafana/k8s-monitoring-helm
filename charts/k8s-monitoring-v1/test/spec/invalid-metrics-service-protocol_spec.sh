Describe 'Invalid protocol for metrics service'
  It 'prints a friendly error message'
    When call helm template k8smon .. -f "spec/fixtures/invalid-metrics-service-protocol_values.yaml"
    The status should be failure
    The error should include 'Error: values don'"'"'t meet the specifications of the schema(s) in the following chart(s):
k8s-monitoring:
- externalServices.prometheus.protocol: externalServices.prometheus.protocol must be one of the following: "remote_write", "otlp", "otlphttp"'
  End
End
