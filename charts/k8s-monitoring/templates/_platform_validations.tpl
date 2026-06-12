{{- /*
Detects the platform this cluster is running on by inspecting the available API
versions and the metadata of the cluster's nodes. Returns the detected platform
name ("openshift", "aks", "gke", or "eks"), or an empty string if the platform
could not be determined. Input: . (root context)
*/ -}}
{{ define "validations.platform.detect" -}}
  {{- $platform := "" }}
  {{- if ((.Capabilities).APIVersions.Has "security.openshift.io/v1/SecurityContextConstraints") }}
    {{- $platform = "openshift" }}
  {{- end }}

  {{- $nodes := list }}
  {{- if eq $platform "" }}
    {{- $nodes = (dig "items" list (lookup "v1" "Node" "" "" | default dict)) }}
  {{- end }}

  {{- range $node := $nodes }}
    {{- if eq $platform "" }}
      {{- /* Inspect well-known node labels added by the managed Kubernetes providers. */ -}}
      {{- range $label, $value := $node.metadata.labels }}
        {{- if eq $platform "" }}
          {{- if regexMatch "^kubernetes\\.azure\\.com/" $label }}
            {{- $platform = "aks" }}
          {{- else if regexMatch "^cloud\\.google\\.com/gke" $label }}
            {{- $platform = "gke" }}
          {{- else if regexMatch "^eks\\.amazonaws\\.com/" $label }}
            {{- $platform = "eks" }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- /* Fall back to the node's cloud provider ID when the labels are inconclusive. */ -}}
      {{- if eq $platform "" }}
        {{- $providerID := (dig "spec" "providerID" "" $node) }}
        {{- if hasPrefix "azure://" $providerID }}
          {{- $platform = "aks" }}
        {{- else if hasPrefix "gce://" $providerID }}
          {{- $platform = "gke" }}
        {{- else if hasPrefix "aws://" $providerID }}
          {{- $platform = "eks" }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $platform }}
{{- end }}

{{- /*
Resolves the platform for this cluster: returns the explicitly configured
`global.platform` if set, otherwise the auto-detected platform, or an empty
string if neither is available. Input: . (root context)
*/ -}}
{{ define "validations.platform.resolve" -}}
  {{- if .Values.global.platform -}}
    {{- .Values.global.platform -}}
  {{- else -}}
    {{- include "validations.platform.detect" . | trim -}}
  {{- end -}}
{{- end }}

{{ define "validations.platform" -}}
  {{- $platform := include "validations.platform.detect" . | trim }}
  {{- if eq $platform "openshift" }}
    {{- include "validations.platform.openshift" . }}
  {{- else if eq $platform "aks" }}
    {{- include "validations.platform.aks" . }}
  {{- end }}
{{- end }}

{{ define "validations.platform.aks" -}}
  {{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
    {{- $collectorValues := (include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml) }}
    {{- if ne (dig "controller" "podAnnotations" "kubernetes.azure.com/set-kube-service-host-fqdn" "false" $collectorValues) "true" }}
      {{- $msg := list "" "This Kubernetes cluster appears to be Azure AKS." }}
      {{- $msg = append $msg "To ensure connectivity to the API server, please set:" }}
      {{- $msg = append $msg (printf "%s:" $collectorName) }}
      {{- $msg = append $msg "  controller:" }}
      {{- $msg = append $msg "    podAnnotations:" }}
      {{- $msg = append $msg "      kubernetes.azure.com/set-kube-service-host-fqdn: \"true\"" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
  {{- if and ($.Values.clusterMetrics.enabled) ((index $.Values.clusterMetrics "kube-state-metrics").enabled) ((index $.Values.telemetryServices "kube-state-metrics").deploy) }}
    {{- if ne (dig "podAnnotations" "kubernetes.azure.com/set-kube-service-host-fqdn" "false" (index $.Values.telemetryServices "kube-state-metrics")) "true" }}
      {{- $msg := list "" "This Kubernetes cluster appears to be Azure AKS." }}
      {{- $msg = append $msg "To ensure connectivity to the API server, please set:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  kube-state-metrics:" }}
      {{- $msg = append $msg "    podAnnotations:" }}
      {{- $msg = append $msg "      kubernetes.azure.com/set-kube-service-host-fqdn: \"true\"" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}

{{ define "validations.platform.openshift" -}}
  {{- if not (eq .Values.global.platform "openshift") }}
    {{- $msg := list "" "This Kubernetes cluster appears to be OpenShift. Please set the platform to enable compatibility:" }}
    {{- $msg = append $msg "global:" }}
    {{- $msg = append $msg "  platform: openshift" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
