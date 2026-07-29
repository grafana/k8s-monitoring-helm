Describe 'KEDA Autoscaling Check'
  Describe 'Using an externally managed HPA'
    It 'configures the Alloy collector to let KEDA own the replica count'
      When call grep -F 'externalHPA: true' ../../docs/examples/scalability/keda-autoscaling/output.yaml
      The status should be success
      The output should equal '        externalHPA: true'
    End
  End
End
