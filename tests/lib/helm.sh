template() {
  helm template k8smon ../charts/k8s-monitoring -f "${1}"
}