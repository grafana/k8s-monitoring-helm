{{ define "validations.platform" -}}
  {{- if (.Capabilities.APIVersions.Has "security.openshift.io/v1/SecurityContextConstraints") }}
    {{- include "validations.platform.openshift" . }}
  {{- end }}

  {{- range $node := (lookup "v1" "Node" "" "").items }}
    {{- range $label, $value := $node.metadata.labels }}
      {{- if regexMatch "kubernetes.azure.com.*" $label }}
        {{- include "validations.platform.aks" $ }}
        {{- break }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{ define "validations.platform.aks" -}}
  {{- range $collector := (include "collectors.list.enabled" .) | fromYamlArray }}
    {{- if ne (dig "controller" "podAnnotations" "kubernetes.azure.com/set-kube-service-host-fqdn" "false" (index $.Values $collector)) "true" }}
      {{- $msg := list "" "This Kubernetes cluster appears to be Azure AKS." }}
      {{- $msg = append $msg "To ensure connectivity to the API server, please set:" }}
      {{- $msg = append $msg (printf "%s:" $collector) }}
      {{- $msg = append $msg "  controller:" }}
      {{- $msg = append $msg "    podAnnotations:" }}
      {{- $msg = append $msg "      kubernetes.azure.com/set-kube-service-host-fqdn: \"true\"" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
  {{- if and ($.Values.clusterMetrics.enabled) ((index $.Values.clusterMetrics "kube-state-metrics").enabled) }}
    {{- if ne (dig "podAnnotations" "kubernetes.azure.com/set-kube-service-host-fqdn" "false" (index $.Values.clusterMetrics "kube-state-metrics")) "true" }}
      {{- $msg := list "" "This Kubernetes cluster appears to be Azure AKS." }}
      {{- $msg = append $msg "To ensure connectivity to the API server, please set:" }}
      {{- $msg = append $msg "clusterMetrics:" }}
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
