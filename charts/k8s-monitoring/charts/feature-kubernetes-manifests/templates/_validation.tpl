{{- define "feature.kubernetesManifests.validate" }}
{{- $atLeastOneKindIsEnabled := false }}
{{- range $kind := keys .Values.kinds }}
  {{- if dig $kind "gather" false $.Values.kinds }}
    {{- $atLeastOneKindIsEnabled = true }}
  {{- end }}
{{- end }}
{{- if not $atLeastOneKindIsEnabled }}
  {{- $msg := list "" "At least one manifest kind must be enabled to use Kubernetes Manifest gathering." }}
  {{- $msg = append $msg "Please enable one. For example:" }}
  {{- $msg = append $msg "kubernetesManifests:" }}
  {{- $msg = append $msg "  kinds:" }}
  {{- $msg = append $msg "    pods:" }}
  {{- $msg = append $msg "      gather: true" }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-kubernetes-manifests for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
