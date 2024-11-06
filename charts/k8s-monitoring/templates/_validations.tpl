{{/* Checks that the cluster name is defined */}}
{{- define "validations.cluster_name" }}
{{- if not .Values.cluster.name }}
  {{- $msg := list "" "A Cluster name is required!" }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "cluster:" }}
  {{- $msg = append $msg "  name: my-cluster-name" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Checks that at least one feature is enabled */}}
{{- define "validations.features_enabled" }}
{{ $aFeatureIsEnabled := false }}
{{- range $feature := ((include "features.list" .) | fromYamlArray ) }}
  {{- $aFeatureIsEnabled = or $aFeatureIsEnabled (eq (include (printf "features.%s.enabled" $feature) $) "true") }}
{{- end }}
{{- range $collector := ((include "collectors.list" .) | fromYamlArray ) }}
  {{- $aFeatureIsEnabled = or $aFeatureIsEnabled ((index $.Values $collector).remoteConfig.enabled) }}
  {{- $aFeatureIsEnabled = or $aFeatureIsEnabled ((index $.Values $collector).extraConfig) }}
{{- end }}
{{- if not $aFeatureIsEnabled }}
  {{- $msg := list "" "No features are enabled. Please choose a feature to start monitoring. For example:" }}
  {{- $msg = append $msg "clusterMetrics:" }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/Features.md for the list of available features." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Checks for platform settings */}}
{{- define "validations.platform" }}
{{- if and (not (eq .Values.global.platform "openshift")) (.Capabilities.APIVersions.Has "security.openshift.io/v1/SecurityContextConstraints") }}
  {{- $msg := list "" "This Kubernetes cluster appears to be OpenShift. Please set the platform to enable compatibility:" }}
  {{- $msg = append $msg "global:" }}
  {{- $msg = append $msg "  platform: openshift" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
