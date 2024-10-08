findUnmodifiedImageRegisries() {
  grep "image: " ../../docs/examples/private-image-registries/output.yaml | grep -v "my.registry.com"
}

Describe 'Private Registry Check'
  Describe 'Using private registry'
    It 'does not contain any image references not in the image registry'
      When call findUnmodifiedImageRegisries
      The status should be failure
      The output should equal ''
    End
  End
End
