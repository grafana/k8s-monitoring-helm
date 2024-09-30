Describe 'Receiver Port Check'
  Describe 'Missing Otel gRPC port'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/missing-otel-grpc-port_values.yaml"
      The status should be failure
      The error should include 'OTLP gRPC port not opened on Grafana Alloy.
In order to receive data over this protocol, port 4317 needs to be opened on Alloy. For example, set this in your values file:
alloy:
  alloy:
    extraPorts:
      - name: "otlp-grpc"
        port: 4317
        targetPort: 4317
        protocol: "TCP"
For more examples, see https://github.com/grafana/k8s-monitoring-helm/tree/main/examples/traces-enabled

Use --debug flag to render out invalid YAML'
    End
  End

  Describe 'Missing Otel HTTP port'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/missing-otel-http-port_values.yaml"
      The status should be failure
      The error should include 'OTLP HTTP port not opened on Grafana Alloy.
In order to receive data over this protocol, port 4318 needs to be opened on Alloy. For example, set this in your values file:
alloy:
  alloy:
    extraPorts:
      - name: "otlp-http"
        port: 4318
        targetPort: 4318
        protocol: "TCP"
For more examples, see https://github.com/grafana/k8s-monitoring-helm/tree/main/examples/traces-enabled

Use --debug flag to render out invalid YAML'
    End
  End

  Describe 'Missing Prometheus port'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/missing-prometheus-port_values.yaml"
      The status should be failure
      The error should include 'Prometheus port not opened on Grafana Alloy.
In order to receive data over this protocol, port 9999 needs to be opened on Alloy. For example, set this in your values file:
alloy:
  alloy:
    extraPorts:
      - name: "prometheus"
        port: 9999
        targetPort: 9999
        protocol: "TCP"
For more examples, see https://github.com/grafana/k8s-monitoring-helm/tree/main/examples/traces-enabled

Use --debug flag to render out invalid YAML'
    End
  End

  Describe 'Missing Zipkin port'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/missing-zipkin-port_values.yaml"
      The status should be failure
      The error should include 'Zipkin port not opened on Grafana Alloy.
In order to receive data over this protocol, port 9411 needs to be opened on Alloy. For example, set this in your values file:
alloy:
  alloy:
    extraPorts:
      - name: "zipkin"
        port: 9411
        targetPort: 9411
        protocol: "TCP"
For more examples, see https://github.com/grafana/k8s-monitoring-helm/tree/main/examples/traces-enabled

Use --debug flag to render out invalid YAML'
    End
  End

  Describe 'Error message works with alternative ports'
    It 'prints a friendly error message'
      When call helm template k8smon .. -f "spec/fixtures/missing-alternative-port_values.yaml"
      The status should be failure
      The error should include 'OTLP HTTP port not opened on Grafana Alloy.
In order to receive data over this protocol, port 8080 needs to be opened on Alloy. For example, set this in your values file:
alloy:
  alloy:
    extraPorts:
      - name: "otlp-http"
        port: 8080
        targetPort: 8080
        protocol: "TCP"
For more examples, see https://github.com/grafana/k8s-monitoring-helm/tree/main/examples/traces-enabled

Use --debug flag to render out invalid YAML'
    End
  End
End
