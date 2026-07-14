findUnmodifiedImageRegistries() {
  grep "image: " ../../docs/examples/private-image-registries/globally/output.yaml | grep -v "my.registry.com"
  grep "image: " ../../docs/examples/private-image-registries/individual/output.yaml | grep -v "my.registry.com"
}

# The "globally" example sets global.image.pullPolicy: Always. Every component this chart manages directly
# (the Alloy instances, the Alloy Operator, and the Alloy removal hooks) must honor it. Third-party dependency
# charts do not honor a global pull policy, so they are intentionally excluded.
findChartManagedNonAlwaysPullPolicies() {
  awk '
    /# Source:/ { source = $3 }
    /imagePullPolicy:/ && (source ~ /alloy-operator\/templates\/deployment\.yaml$/ || source ~ /templates\/hooks\//) {
      if ($2 != "Always") print source": "$2
    }
    /pullPolicy:/ && $0 !~ /imagePullPolicy:/ && source ~ /templates\/alloy(-[a-z]+)?\.yaml$/ {
      if ($2 != "Always") print source": "$2
    }
  ' ../../docs/examples/private-image-registries/globally/output.yaml
}

Describe 'Private Registry Check'
  Describe 'Using private registry'
    It 'does not contain any image references not in the image registry'
      When call findUnmodifiedImageRegistries
      The status should be failure
      The output should equal ''
    End

    It 'applies the global image pull policy to every component this chart manages'
      When call findChartManagedNonAlwaysPullPolicies
      The status should be success
      The output should equal ''
    End
  End
End
