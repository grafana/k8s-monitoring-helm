{{- define "collectors.notes.deployments" }}
{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- $type := $collectorValues.controller.type | default "daemonset" }}
  {{- $replicas := $collectorValues.controller.replicas | default 1 | int }}
  {{- if ne $type "daemonset" }}
    {{- $type = printf "%s, %d replica" $type $replicas }}
    {{- if gt $replicas 1 }}{{- $type = printf "%ss" $type }}{{- end }}
  {{- end }}
* Grafana Alloy "{{ $collectorName }}" ({{ $type }})
{{- end }}
{{- end }}

{{/* Entry point for collector-level warnings. Add new collector warning notes here. */}}
{{- define "collectors.notes.warnings" }}
{{- include "collectors.notes.istio" . }}
{{- include "collectors.notes.remoteConfigInferredAuth" . }}
{{- include "collectors.notes.rbac" . }}
{{- end }}

{{/* Points collectors with rbac.mode "minimal" to the annotations that explain their RBAC. */}}
{{- define "collectors.notes.rbac" }}
{{- $remoteConfig := list }}
{{- $restricted := list }}
{{- $userConfig := or .Values.replaceComponent }}
{{- range $_, $destination := .Values.destinations | default dict }}
  {{- if eq (dig "type" "" $destination) "custom" }}{{ $userConfig = true }}{{ end }}
{{- end }}
{{- range $_, $processor := .Values.dataProcessors | default dict }}
  {{- if eq (dig "type" "" $processor) "custom" }}{{ $userConfig = true }}{{ end }}
{{- end }}
{{- $minimal := list }}
{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- if eq (dig "rbac" "mode" "alloy" $collectorValues) "minimal" }}
    {{- if ne (include "collector.alloy.rbacMode" $collectorValues) "minimal" }}
      {{- $remoteConfig = append $remoteConfig $collectorName }}
    {{- else if dig "rbac" "create" true $collectorValues }}
      {{- $minimal = append $minimal $collectorName }}
      {{- if $collectorValues.extraConfig }}{{ $userConfig = true }}{{ end }}
      {{- if dig "rbac" "namespaces" list $collectorValues }}
        {{- $restricted = append $restricted $collectorName }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if $remoteConfig }}

⚠️ These collectors use remote configuration, which can run any component, so they keep the Alloy Operator's default
RBAC even though rbac.mode is "minimal":
{{- range $remoteConfig }}
* {{ . }}
{{- end }}
{{- end }}
{{- if and $minimal $userConfig }}

Collectors with rbac.mode "minimal" are granted RBAC for the Kubernetes components in user-supplied configuration. The
k8s.grafana.com/rbac-user-config annotation on their ClusterRole and Roles lists those grants.
{{- end }}
{{- if $restricted }}

⚠️ These collectors set rbac.namespaces, so they aren't granted cluster-scoped permissions. If they need any, the
k8s.grafana.com/rbac-dropped annotation on their Roles lists them, and the components that use them may not find any
data:
{{- range $restricted }}
* {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/* Warns when a collector's remote configuration authentication type is being inferred as "basic". */}}
{{- define "collectors.notes.remoteConfigInferredAuth" }}
{{- $affected := list }}
{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- if dig "remoteConfig" "enabled" false $collectorValues }}
    {{- $auth := dig "remoteConfig" "auth" dict $collectorValues }}
    {{- $hasUsername := or $auth.username $auth.usernameFrom }}
    {{- $hasPassword := or $auth.password $auth.passwordFrom }}
    {{- if and (not $auth.type) $hasUsername $hasPassword }}
      {{- $affected = append $affected $collectorName }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if $affected }}

⚠️ Inferring the remote configuration authentication type as "basic" because a username and password were provided
without an explicit "remoteConfig.auth.type"

Affected collector(s):
{{- range $name := $affected }}
* {{ $name }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Detects if the release namespace is part of an Istio Service Mesh and warns when any clustered
Alloy collector is using a clustering port name that Istio will not route for headless Services
(any name starting with "http"). Without this fix, clustering peers cannot discover each other,
causing each replica to independently scrape all targets and emit duplicate metrics.
*/}}
{{- define "collectors.notes.istio" }}
{{- $namespace := lookup "v1" "Namespace" "" .Release.Namespace }}
{{- if $namespace }}
  {{- $nsLabels := $namespace.metadata.labels | default dict }}
  {{- $istioLabel := "" }}
  {{- if hasKey $nsLabels "istio.io/dataplane-mode" }}
    {{- $istioLabel = printf "istio.io/dataplane-mode=%s" (index $nsLabels "istio.io/dataplane-mode") }}
  {{- else if eq (index $nsLabels "istio-injection" | default "") "enabled" }}
    {{- $istioLabel = "istio-injection=enabled" }}
  {{- else if hasKey $nsLabels "istio.io/rev" }}
    {{- $istioLabel = printf "istio.io/rev=%s" (index $nsLabels "istio.io/rev") }}
  {{- end }}
  {{- if $istioLabel }}
    {{- $affected := list }}
    {{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
      {{- $collectorValues := include "collector.alloy.valuesWithUpstream" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
      {{- if dig "alloy" "clustering" "enabled" false $collectorValues }}
        {{- $portName := dig "alloy" "clustering" "portName" "http" $collectorValues }}
        {{- if hasPrefix "http" $portName }}
          {{- $affected = append $affected $collectorName }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- if $affected }}

⚠️ The "{{ .Release.Namespace }}" namespace appears to be part of an Istio Service Mesh (label: {{ $istioLabel }}).
Istio does not route headless Service ports whose name starts with "http", which breaks Alloy
clustering peer discovery. Each replica will scrape all targets independently and emit duplicate
metrics.

Affected collector(s) with clustering enabled:
{{- range $name := $affected }}
* {{ $name }}
{{- end }}

To fix, set the clustering port name to a non-HTTP value (for example "tcp"):

collectors:
{{- range $name := $affected }}
  {{ $name }}:
    alloy:
      clustering:
        portName: tcp
{{- end }}

See: https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/examples/istio-service-mesh
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
