# The Makefile renders every example with rbac.mode: minimal into .rendered/rbac-minimal. The chart annotates RBAC
# objects with k8s.grafana.com/rbac-inferred when the configuration uses a Kubernetes API component that the computed
# rules don't cover. rbac_minimal_known_gaps.txt lists the annotations expected for features that don't compute their
# own rules yet, so any other annotation means a feature's RBAC rules are out of date.
findInferredRBAC() {
  grep -r "k8s.grafana.com/rbac-inferred" .rendered/rbac-minimal | sed 's|^\.rendered/rbac-minimal/||; s|:[[:space:]]*k8s.grafana.com/rbac-inferred: "\(.*\)"$|: \1|' | sort -u
}

compareToKnownGaps() {
  findInferredRBAC | diff spec/rbac_minimal_known_gaps.txt -
}

Describe 'Minimal RBAC Check'
  Describe 'Rendering every example with rbac.mode: minimal'
    It 'computes rules that cover every Kubernetes API component, except the known gaps'
      When call compareToKnownGaps
      The status should be success
      The output should equal ''
    End
  End
End
