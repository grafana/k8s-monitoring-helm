{{/* Validates that the Alloy instance is appropriate for the given Pod Logs settings */}}
{{/* Inputs: Values (Pod Logs values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.podLogs.collector.validate" -}}
{{- if or (and .Values.volumeGathering.enabled (not .Values.gatherMethod)) (eq .Values.gatherMethod "volumes") }}
  {{- if not (eq .Collector.controller.type "daemonset") }}
    {{- fail (printf "Pod Logs feature requires Alloy to be a DaemonSet when using the \"volumes\" gather method.\nPlease set:\n%s:\n  controller:\n    type: daemonset" .CollectorName) }}
  {{- end -}}
  {{- if not .Collector.alloy.mounts.varlog }}
    {{- fail (printf "Pod Logs feature requires Alloy to mount /var/log when using the \"volumes\" gather method.\nPlease set:\n%s:\n  alloy:\n    mounts:\n      varlog: true" .CollectorName) }}
  {{- end -}}
{{- end -}}

{{- if or (and .Values.kubernetesApiStreaming.enabled (not .Values.gatherMethod)) (eq .Values.gatherMethod "kubernetesApi") }}
  {{- if not .Collector.alloy.clustering.enabled }}
    {{- if eq .Collector.controller.type "daemonset" }}
      {{- fail (printf "Pod Logs feature requires Alloy DaemonSet to be in clustering mode when using the \"kubernetesApi\" gather method.\nPlease set:\n%s:\n  alloy:\n    clustering:\n      enabled: true" .CollectorName) }}
    {{- else if gt (.Collector.controller.replicas | int) 1 }}
      {{- fail (printf "Pod Logs feature requires Alloy with multiple replicas to be in clustering mode when using the \"kubernetesApi\" gather method.\nPlease set:\n%s:\n  alloy:\n    clustering:\n      enabled: true" .CollectorName) }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "feature.podLogs.validate" -}}
{{/*Validate that if both volume gathering and k8s api gathering, there are some selectors set*/}}
{{- if and .Values.volumeGathering.enabled .Values.kubernetesApiStreaming.enabled }}
  {{- if not (or .Values.kubernetesApiStreaming.labelSelectors .Values.kubernetesApiStreaming.fieldSelectors .Values.kubernetesApiStreaming.nodeLabelSelectors .Values.kubernetesApiStreaming.nodeFieldSelectors)}}
    {{- $msg := list "" "When gathering Pod logs by Volumes and the Kubernetes API, you must set selectors to targets pods not covered by the Collector DaemonSet." }}
    {{- $msg = append $msg "Please set at least one of:" }}
    {{- $msg = append $msg "podLogs:" }}
    {{- $msg = append $msg "  kubernetesApiStreaming:" }}
    {{- $msg = append $msg "    fieldSelectors: [<field selector>]" }}
    {{- $msg = append $msg "    labelSelectors:" }}
    {{- $msg = append $msg "      <Kubernetes Pod Label>: <value> OR [<value1>, <value2>]" }}
    {{- $msg = append $msg "    nodeFieldSelectors: [<field selector>]" }}
    {{- $msg = append $msg "    nodeLabelSelectors:" }}
    {{- $msg = append $msg "      <Kubernetes Node Label>: <value> OR [<value1>, <value2>]" }}
    {{- $errorMessage := join "\n" $msg }}
  {{- end -}}
{{- end -}}

{{- if .Values.openShiftClusterLogForwarder.enabled }}
  {{- if not (eq .Values.global.platform "openshift") }}
    {{- $msg := list "" "The OpenShift ClusterLogForwarder is only supported on OpenShift clusters." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "global:" }}
    {{- $msg = append $msg "  platform: openshift" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- if not .Values.lokiReceiver.enabled }}
    {{- $msg := list "" "The OpenShift ClusterLogForwarder requires the Loki Receiver to be enabled." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "podLogs:" }}
    {{- $msg = append $msg "  lokiReceiver:" }}
    {{- $msg = append $msg "    enabled: true" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

{{- end }}

{{- end -}}
