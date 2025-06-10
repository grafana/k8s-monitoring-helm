Describe 'Embedded Secrets Check'
  Describe 'Using secret.embed = true'
    It 'does not create any Kubernetes Secrets'
      When call wget --spider --server-response https://github.com/grafana/alloy-operator/releases/download/alloy-operator-${ALLOY_OPERATOR_VERSION}/collectors.grafana.com_alloy.yaml
      The status should be success
      The stderr should include 'HTTP/1.1 200 OK'
      The stderr should include 'Content-Type: application/octet-stream'
      The stderr should include 'remote file exists'
    End
  End
End
