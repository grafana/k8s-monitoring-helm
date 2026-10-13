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

{{/* Explains what collectors with rbac.mode "minimal" were granted, or why they weren't. */}}
{{- define "collectors.notes.rbac" }}
{{- $remoteConfig := list }}
{{- $scanned := list }}
{{- $dropped := list }}
{{- $replacements := list }}
{{- range $replacement := .Values.replaceComponent | default list }}
  {{- $replacements = append $replacements (printf "%s \"%s\" {\n%s\n}" $replacement.type $replacement.name $replacement.content) }}
{{- end }}
{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $values := dict "Values" $.Values "Chart" $.Chart "Files" $.Files "Release" $.Release "Subcharts" $.Subcharts "Template" $.Template "Capabilities" $.Capabilities "collectorName" $collectorName }}
  {{- $collectorValues := include "collector.alloy.values" $values | fromYaml }}
  {{- if eq (dig "rbac" "mode" "alloy" $collectorValues) "minimal" }}
    {{- if ne (include "collector.alloy.rbacMode" $collectorValues) "minimal" }}
      {{- $remoteConfig = append $remoteConfig $collectorName }}
    {{- else if dig "rbac" "create" true $collectorValues }}
      {{- $featureKeys := include "collectors.features" $values | fromYamlArray }}
      {{- $rbacContext := merge (dict "featureKeys" $featureKeys "extraConfig" (include "collectors.extraConfig.alloy" $values | trim) "replacements" $replacements) $values }}
      {{- $_ := set $rbacContext "destinationNames" (include "collectors.destinationNames" $rbacContext | fromYamlArray) }}
      {{- $computed := include "collectors.rbac.compute" (dict
        "Files" $.Files
        "collectorValues" $collectorValues
        "entries" (include "collectors.rbac.entries" $rbacContext | fromYamlArray)
        "userConfig" (include "collectors.rbac.userConfig" $rbacContext | fromYamlArray)) | fromYaml }}
      {{- range $component := $computed.userComponents }}
        {{- $scanned = append $scanned (printf "%s: %s" $collectorName $component) }}
      {{- end }}
      {{- if $computed.resolved.dropped }}
        {{- $dropped = append $dropped (printf "%s: %s" $collectorName (join ", " $computed.resolved.dropped)) }}
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
{{- if $scanned }}

These collectors were granted cluster-wide RBAC for the Kubernetes components found in user-supplied configuration:
{{- range $scanned }}
* {{ . }}
{{- end }}
To limit this access to some namespaces, set rbac.namespaces on the collector.
{{- end }}
{{- if $dropped }}

⚠️ These collectors set rbac.namespaces, so they were not granted the cluster-scoped permissions from these bundles,
and the components that need them may not find any data:
{{- range $dropped }}
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
