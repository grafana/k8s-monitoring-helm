# Every example renders with rbac.mode: minimal into .rendered/rbac-minimal, and any rbac-inferred annotation is a gap.
findInferredRBAC() {
  grep -r -A1 "k8s.grafana.com/rbac-inferred" .rendered/rbac-minimal
}

Describe 'Minimal RBAC Check'
  Describe 'Rendering every example with rbac.mode: minimal'
    It 'computes rules that cover every Kubernetes API component'
      When call findInferredRBAC
      The status should be failure
      The output should equal ''
    End
  End
End
