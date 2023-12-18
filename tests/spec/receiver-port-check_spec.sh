Describe 'Receiver Port Check'
  Describe 'Missing Otel gRPC port'
    It 'prints a friendly error message'
      When call helm template k8smon ../charts/k8s-monitoring -f "spec/missing-otel-grpc-port_values.yaml"
      The status should be failure
      The error should include 'OTLP gRPC port not opened on the Grafana Agent.
In order to receive data over this protocol, the 4317 port needs to be opened on the Grafana Agent. For example, set this in your values file:
grafana-agent:
  agent:
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
      When call helm template k8smon ../charts/k8s-monitoring -f "spec/missing-otel-http-port_values.yaml"
      The status should be failure
      The error should include 'OTLP HTTP port not opened on the Grafana Agent.
In order to receive data over this protocol, the 4318 port needs to be opened on the Grafana Agent. For example, set this in your values file:
grafana-agent:
  agent:
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
      When call helm template k8smon ../charts/k8s-monitoring -f "spec/missing-prometheus-port_values.yaml"
      The status should be failure
      The error should include 'Prometheus port not opened on the Grafana Agent.
In order to receive data over this protocol, the 9999 port needs to be opened on the Grafana Agent. For example, set this in your values file:
grafana-agent:
  agent:
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
      When call helm template k8smon ../charts/k8s-monitoring -f "spec/missing-zipkin-port_values.yaml"
      The status should be failure
      The error should include 'Zipkin port not opened on the Grafana Agent.
In order to receive data over this protocol, the 9411 port needs to be opened on the Grafana Agent. For example, set this in your values file:
grafana-agent:
  agent:
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
      When call helm template k8smon ../charts/k8s-monitoring -f "spec/missing-alternative-port_values.yaml"
      The status should be failure
      The error should include 'OTLP HTTP port not opened on the Grafana Agent.
In order to receive data over this protocol, the 8080 port needs to be opened on the Grafana Agent. For example, set this in your values file:
grafana-agent:
  agent:
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
