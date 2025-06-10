{{- define "crdValidation" -}}
{{- $crdURL := printf "https://github.com/grafana/alloy-operator/releases/download/alloy-operator-%s/collectors.grafana.com_alloy.yaml" (index .Subcharts "alloy-operator").Chart.Version }}
{{- if .Release.IsInstall }}
  {{- if not (.Capabilities.APIVersions.Has "collectors.grafana.com/v1alpha1/Alloy") }}
    {{- if not (index .Values "alloy-operator").crds.deployAlloyCRD }}
      {{- $msg := list "" (printf "The %s Helm chart v3.0 requires the Alloy CRD to be deployed." .Chart.Name) }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "alloy-operator:" }}
      {{- $msg = append $msg "  crds:" }}
      {{- $msg = append $msg "    deployAlloyCRD: true" }}
      {{- $msg = append $msg "" "Or install the Alloy CRD manually:" }}
      {{- $msg = append $msg (printf "kubectl apply -f %s" $crdURL) }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if .Release.IsUpgrade }}
  {{- if not (.Capabilities.APIVersions.Has "collectors.grafana.com/v1alpha1/Alloy") }}
    {{- $msg := list "" (printf "The %s Helm chart v3.0 requires the Alloy CRD to be deployed." .Chart.Name) }}
    {{- $msg = append $msg "Before upgrading, please install the Alloy CRD:" }}
    {{- $msg = append $msg (printf "kubectl apply -f %s" $crdURL) }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}
