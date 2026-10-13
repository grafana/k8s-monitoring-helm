{{- define "features.clusterMetrics.enabled" }}{{ .Values.clusterMetrics.enabled }}{{- end }}

{{- define "features.clusterMetrics.include" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray }}
// Feature: Cluster Metrics
{{- include "feature.clusterMetrics.module" (dict "Values" $.Values.clusterMetrics "Files" $.Subcharts.clusterMetrics.Files "Release" $.Release "telemetryServices" $.Values.telemetryServices) }}
cluster_metrics "feature" {
  metrics_destinations = [
    {{ include "dataProcessors.pipeline.targets.forFeature" (dict "root" $ "featureKey" "clusterMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- include "dataProcessors.pipeline.render.forFeature" (dict "root" $ "featureKey" "clusterMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end -}}
{{- end -}}

{{- define "features.clusterMetrics.destinations" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.clusterMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.clusterMetrics.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.clusterMetrics.collector.values" }}{{- end -}}

{{- define "features.clusterMetrics.validate" }}
{{- if .Values.clusterMetrics.enabled }}
  {{- $featureKey := "clusterMetrics" }}
  {{- $featureName := "Kubernetes Cluster metrics" }}
  {{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName "Values" $.Values "featureKey" $featureKey) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" $featureKey "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
  {{- include "collectors.validate.clusteringEnabled" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName "featureName" $featureName) }}

  {{- include "feature.clusterMetrics.validate" (dict "Values" $.Values.clusterMetrics "telemetryServices" $.Values.telemetryServices) }}
{{- end }}
{{- end }}

{{- define "features.clusterMetrics.rbac" }}
{{- $entries := list }}
{{- $v := .Values.clusterMetrics }}
{{- if $v.enabled }}
  {{- $featureContext := dict "Values" $v "Release" $.Release "telemetryServices" $.Values.telemetryServices }}
  {{- range $source := list "kubelet" "kubeletResource" "kubeletProbes" "cadvisor" }}
    {{- $sourceValues := index $v $source }}
    {{- if $sourceValues.enabled }}
      {{- $entries = append $entries (dict "bundle" "nodes") }}
      {{- if eq $sourceValues.nodeAddressFormat "proxy" }}
        {{- $entries = append $entries (dict "bundle" "kubeletProxy") }}
      {{- else }}
        {{- $entries = append $entries (dict "bundle" "kubeletMetrics") }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if eq (include "feature.clusterMetrics.apiServer.enabled" $featureContext) "true" }}
    {{- $entries = append $entries (dict "bundle" "endpointslices" "namespaces" (list "default")) }}
    {{- $entries = append $entries (dict "bundle" "metricsEndpoint") }}
  {{- end }}
  {{- range $source := list "kubeControllerManager" "kubeScheduler" }}
    {{- if eq (include (printf "feature.clusterMetrics.%s.enabled" $source) $featureContext) "true" }}
      {{- if eq (index $v $source).discoveryMode "eks-proxy" }}
        {{- $entries = append $entries (dict "bundle" "eksControlPlaneMetrics") }}
      {{- else }}
        {{- $entries = append $entries (dict "bundle" "pods" "namespaces" (list "kube-system")) }}
        {{- $entries = append $entries (dict "bundle" "metricsEndpoint") }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if eq (include "feature.clusterMetrics.kubeProxy.enabled" $featureContext) "true" }}
    {{- $entries = append $entries (dict "bundle" "pods" "namespaces" (list "kube-system")) }}
  {{- end }}
  {{- if eq (include "feature.clusterMetrics.kubeDNS.enabled" $featureContext) "true" }}
    {{- $entries = append $entries (dict "bundle" "endpointslices" "namespaces" (list "kube-system")) }}
  {{- end }}
  {{- $ksm := index $v "kube-state-metrics" }}
  {{- if $ksm.enabled }}
    {{- $bundles := dict "endpoints" "endpoints" "endpointslice" "endpointslices" "service" "services" "pod" "pods" }}
    {{- $namespace := include "feature.clusterMetrics.kube_state_metrics.namespace" $featureContext }}
    {{- $entries = append $entries (dict "bundle" (get $bundles $ksm.discoveryType | default $ksm.discoveryType) "namespaces" (compact (list $namespace))) }}
    {{- $entries = append $entries (dict "bundle" "metricsEndpoint") }}
  {{- end }}
{{- end }}
{{- $entries | toYaml }}
{{- end }}
