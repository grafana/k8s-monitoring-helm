{{- define "feature.clusterMetrics.validate.disabledDeployments" }}
{{- if and (not (index .Values .key).enabled) (index .Values .key).deploy }}
  {{- $msg := list "" (printf "For the Cluster Metrics feature, %s is disabled but it will still be deployed." .name) }}
  {{- $msg = append $msg "If you do not want these metrics, disable the deployment by setting:" }}
  {{- $msg = append $msg "clusterMetrics:" }}
  {{- $msg = append $msg (printf "  %s:" .key) }}
  {{- $msg = append $msg "    enabled: false" }}
  {{- $msg = append $msg "    deploy: false" }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "If you do want these metrics, enable it by setting:" }}
  {{- $msg = append $msg "clusterMetrics:" }}
  {{- $msg = append $msg (printf "  %s:" .key) }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{- define "feature.clusterMetrics.validate" }}
  {{- include "feature.clusterMetrics.validate.disabledDeployments" (dict "Values" .Values "key" "kube-state-metrics" "name" "kube-state-metrics" )}}
  {{- include "feature.clusterMetrics.validate.disabledDeployments" (dict "Values" .Values "key" "node-exporter" "name" "Node Exporter" )}}
  {{- include "feature.clusterMetrics.validate.disabledDeployments" (dict "Values" .Values "key" "windows-exporter" "name" "Windows Exporter" )}}
{{- end }}
