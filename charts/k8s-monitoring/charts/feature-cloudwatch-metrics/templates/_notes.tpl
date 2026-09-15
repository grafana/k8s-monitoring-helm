{{- define "feature.cloudwatchMetrics.notes.deployments" }}{{- end }}

{{- define "feature.cloudwatchMetrics.notes.task" }}
{{- $regions := list }}
{{- range $instance := .Values.instances }}
  {{- range $region := ($instance.regions | default list) }}
    {{- if not (has $region $regions) }}
      {{- $regions = append $regions $region }}
    {{- end }}
  {{- end }}
{{- end }}
Gather AWS CloudWatch metrics from {{ len .Values.instances }} exporter instance{{ if ne (len .Values.instances) 1 }}s{{ end }}
{{- if $regions }} in the regions {{ $regions | sortAlpha | join "," }}{{ end }}
{{- end }}

{{- /* Unlike notes.task and notes.deployments, NOTES.txt calls notes.actions with the root context, so the feature's
       own values are reached through .Values.cloudwatchMetrics rather than .Values. */ -}}
{{- define "feature.cloudwatchMetrics.notes.actions" }}
{{- $usesRoles := false }}
{{- range $instance := .Values.cloudwatchMetrics.instances }}
  {{- if $instance.roles }}{{ $usesRoles = true }}{{ end }}
  {{- range $job := concat ($instance.discoveryJobs | default list) ($instance.staticJobs | default list) ($instance.customNamespaceJobs | default list) }}
    {{- if $job.roles }}{{ $usesRoles = true }}{{ end }}
  {{- end }}
{{- end }}
{{- if not $usesRoles }}
* The CloudWatch exporter uses the AWS credentials available to the collector Pod. Be sure its ServiceAccount is
  annotated for IRSA, or that EKS Pod Identity is associated with it, and that the role allows
  cloudwatch:GetMetricData, cloudwatch:ListMetrics, tag:GetResources, and the list/describe calls for the services
  being gathered.
{{- end }}
{{- end }}

{{- define "feature.cloudwatchMetrics.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
