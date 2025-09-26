{{- define "collectors.list" -}}
- alloy-metrics
- alloy-singleton
- alloy-logs
- alloy-receiver
- alloy-profiles
{{- end }}

{{- define "collectors.list.enabled" -}}
{{- range $collector := (include "collectors.list" . | fromYamlArray) }}
  {{- if (index $.Values $collector).enabled }}
- {{ $collector }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Inputs: Values (all values), name (collector name), feature (feature name) */}}
{{- define "collectors.require_collector" -}}
{{- if not (index .Values .name).enabled }}
  {{- $msg := list "" }}
  {{- $msg = append $msg (printf "The %s feature requires the use of the %s collector." .feature .name ) }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "Please enable it by setting:" }}
  {{- $msg = append $msg (printf "%s:" .name) }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Inputs: Values (all values), name (collector name), portNumber */}}
{{- define "collectors.has_extra_port" -}}
{{- $found := "false" -}}
{{- range (index .Values .name).alloy.extraPorts -}}
  {{- if eq (int .targetPort) (int $.portNumber) }}
    {{- $found = "true" -}}
  {{- end }}
{{- end }}
{{- $found -}}
{{- end }}

{{/* Inputs: Values (all values), name (collector name), feature (feature name), portNumber, portName, portProtocol */}}
{{- define "collectors.require_extra_port" -}}
{{- if eq (include "collectors.has_extra_port" .) "false" }}
  {{- $msg := list "" }}
  {{- $msg = append $msg (printf "The %s feature requires that port %d to be open on the %s collector." .feature (.portNumber | int) .name ) }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "Please enable it by setting:" }}
  {{- $msg = append $msg (printf "%s:" .name) }}
  {{- $msg = append $msg "  alloy:" }}
  {{- $msg = append $msg "    extraPorts:" }}
  {{- $msg = append $msg (printf "      - name: %s" .portName) }}
  {{- $msg = append $msg (printf "        port: %d" (.portNumber | int)) }}
  {{- $msg = append $msg (printf "        targetPort: %d" (.portNumber | int)) }}
  {{- $msg = append $msg (printf "        protocol: %s" .portProtocol) }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{- define "collector.alloy.fullname" -}}
  {{- $collectorValues := .collectorValues | default (index .Values .collectorName) }}
  {{- if $collectorValues.fullnameOverride }}
    {{- $collectorValues.fullnameOverride | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- $name := default .collectorName .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
      {{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "collector.alloy.labels" -}}
helm.sh/chart: {{ include "helper.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: alloy
{{- end }}

{{- define "collector.alloy.selectorLabels" -}}
app.kubernetes.io/name: {{ .collectorName }}
app.kubernetes.io/instance: {{ include "collector.alloy.fullname" . }}
{{- end }}

{{- define "collector.alloy.values.global"}}
{{- $globalValues := dict }}
{{- if dig "image" "registry" "" .Values.global }}
  {{- $globalValues = mergeOverwrite $globalValues (dict "global" (dict "image" (dict "registry" .Values.global.image.registry))) }}
{{- end }}
{{- if dig "image" "pullSecrets" "" .Values.global }}
  {{- $globalValues = mergeOverwrite $globalValues (dict "global" (dict "image" (dict "pullSecrets" .Values.global.image.pullSecrets))) }}
{{- end }}
{{- if dig "podSecurityContext" "" .Values.global }}
  {{- $globalValues = mergeOverwrite $globalValues (dict "global" (dict "podSecurityContext" .Values.global.podSecurityContext)) }}
{{- end }}
{{- $globalValues | toYaml }}
{{- end }}

{{- /* Gets the Alloy values. Input: $, .collectorName (string, collector name), .collectorValues (object) */ -}}
{{- define "collector.alloy.values" -}}
{{- /* Values from upstream Alloy */}}
{{- $upstreamValues := "collectors/upstream/alloy-values.yaml" | .Files.Get | fromYaml }}
{{- /* The default settings set for all Alloy instances by this chart */}}
{{- $defaultValues := "collectors/alloy-values.yaml" | .Files.Get | fromYaml }}
{{- /* Values for the specific named Alloy instance */}}
{{- $namedDefaultValues := dict }}
{{- range $fileName, $_ := $.Files.Glob (printf "collectors/named-defaults/%s.yaml" .collectorName) }}
  {{- $namedDefaultValues = ($.Files.Get $fileName | fromYaml) }}
{{- end }}
{{- /* Settings in values.yaml for all Alloy instances */}}
{{- $userCommonValues := $.Values.collectorCommon.alloy }}
{{- /* Copying the this chart's global values to the Alloy instances global values */}}
{{- $globalValues := include "collector.alloy.values.global" . | fromYaml }}
{{- /* Settings in values.yaml for the named instance */}}
{{- $userValues := $.collectorValues }}
{{- if not $.collectorValues }}
  {{- $userValues = (index $.Values .collectorName) }}
{{- end }}
{{ mergeOverwrite $upstreamValues $defaultValues $namedDefaultValues $globalValues $userCommonValues $userValues | toYaml }}
{{- end }}

{{- define "collector.alloy.valuesToSpec" }}
{{- $fieldsToExclude := include "collector.alloy.extraFields" . | fromYamlArray }}
{{- $cleanValues := dict }}
{{- range $key, $val := . }}
  {{- if not (has $key $fieldsToExclude) }}
    {{- $_ := set $cleanValues $key $val }}
  {{- end }}
{{- end }}
{{ $cleanValues | toYaml }}
{{- end }}

{{/* Lists the fields that are not a part of Alloy itself, and should be removed before creating an Alloy instance. */}}
{{/* Inputs: (none) */}}
{{- define "collector.alloy.extraFields" }}
- enabled
- extraConfig
- extraService
- includeDestinations
- liveDebugging
- logging
- remoteConfig
- annotations
- labels
{{- end }}
