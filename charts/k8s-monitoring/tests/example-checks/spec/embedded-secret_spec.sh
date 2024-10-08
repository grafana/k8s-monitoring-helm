Describe 'Embedded Secrets Check'
  Describe 'Using secret.embed = true'
    It 'does not create any Kubernetes Secrets'
      When call grep "kind: Secret" ../../docs/examples/auth/embedded-secrets/output.yaml
      The status should be failure
      The output should equal ''
    End
  End
End
