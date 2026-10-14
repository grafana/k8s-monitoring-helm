# rbac_minimal_known_gaps.txt lists the rbac-inferred annotations expected until every feature computes its own rules.
findInferredRBAC() {
  grep -r "k8s.grafana.com/rbac-inferred" .rendered/rbac-minimal | sed 's|^\.rendered/rbac-minimal/||; s|:[[:space:]]*k8s.grafana.com/rbac-inferred: "\(.*\)"$|: \1|' | LC_ALL=C sort -u
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
