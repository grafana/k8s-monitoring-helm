{{/* Inputs: Values (all values), collectorName (collector name), portNumber */}}
{{- define "collectors.hasExtraPort" -}}
{{- $found := "false" -}}
{{- range $portEntry := (dig .collectorName "alloy" "extraPorts" (list) .Values.collectors) -}}
  {{- if eq (int $portEntry.targetPort) (int $.portNumber) }}
    {{- $found = "true" -}}
  {{- end }}
{{- end }}
{{- $found -}}
{{- end }}

{{/* Inputs: Values (all values), collectorName (collector name), envVarName (environrment var name) */}}
{{- define "collectors.hasExtraEnv" -}}
{{- $found := "false" -}}
{{- range $envVarEntry := dig "alloy" "extraEnv" list (get .Values.collectors .collectorName) -}}
  {{- if eq $envVarEntry.name $.envVarName }}
    {{- $found = "true" -}}
  {{- end }}
{{- end }}
{{- $found -}}
{{- end }}

{{/* Inputs: envList (existing environment var list), name (environrment var name), value (), overwrite */}}
{{- define "collectors.set_extra_env" -}}
{{- $found := false -}}
{{- $newList := list -}}
{{- range .envList -}}
  {{- if eq .name $.name -}}
    {{- $found = true -}}
    {{- if $.overwrite -}}
      {{- if $.value -}}
        {{- $newList = append $newList (dict "name" $.name "value" $.value) -}}
      {{- else if $.valueFrom -}}
        {{- $newList = append $newList (dict "name" $.name "valueFrom" $.valueFrom) -}}
      {{- end -}}
    {{- else -}}
      {{- $newList = append $newList . -}}
    {{- end -}}
  {{- else -}}
    {{- $newList = append $newList . -}}
  {{- end -}}
{{- end -}}
{{- if not $found -}}
  {{- if $.value -}}
    {{- $newList = append $newList (dict "name" $.name "value" $.value) -}}
  {{- else if $.valueFrom -}}
    {{- $newList = append $newList (dict "name" $.name "valueFrom" $.valueFrom) -}}
  {{- end -}}
{{- end -}}
{{- $newList | toYaml -}}
{{- end }}

{{/* Inputs: Values (all values), collectorName (collector name), featureName (feature name), portNumber, portName, portProtocol */}}
{{- define "collectors.requireExtraPort" -}}
{{- if eq (include "collectors.hasExtraPort" .) "false" }}
  {{- $msg := list "" }}
  {{- $msg = append $msg (printf "The %s feature requires that port %d to be open on the %s collector." .featureName (.portNumber | int) .collectorName ) }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "Please enable it by setting:" }}
  {{- $msg = append $msg "collectors:" }}
  {{- $msg = append $msg (printf "  %s:" .collectorName) }}
  {{- $msg = append $msg "    alloy:" }}
  {{- $msg = append $msg "      extraPorts:" }}
  {{- $msg = append $msg (printf "        - name: %s" .portName) }}
  {{- $msg = append $msg (printf "          port: %d" (.portNumber | int)) }}
  {{- $msg = append $msg (printf "          targetPort: %d" (.portNumber | int)) }}
  {{- $msg = append $msg (printf "          protocol: %s" .portProtocol) }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Inputs: Values (all values), collectorName (collector name), collectorValues (collector values, if not inside `.Values.collectors` map) */}}
{{- define "collector.alloy.fullname" }}
  {{- $collectorValues := .collectorValues | default (get .Values.collectors .collectorName) }}
  {{- if hasKey $collectorValues "fullnameOverride" }}
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

{{- define "collector.alloy.labels" }}
helm.sh/chart: {{ include "helper.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: alloy
{{- end }}

{{- define "collector.alloy.selectorLabels" }}
app.kubernetes.io/name: {{ .collectorName }}
app.kubernetes.io/instance: {{ include "collector.alloy.fullname" . }}
{{- end }}

{{- define "collector.alloy.values.global" }}
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
{{- define "collector.alloy.values" }}
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
  {{- $userValues = (index $.Values.collectors .collectorName) }}
{{- end }}
{{- $presetValues := dict }}
{{- if hasKey $userValues "presets" }}
  {{- range $preset := $userValues.presets }}
    {{- $files := $.Files.Glob (printf "collectors/presets/%s.yaml" $preset) }}
    {{- if eq (len $files) 0 }}
      {{ $allPresets := include "collectors.getAllPresets" $ | fromYamlArray }}
      {{- $msg := list "" }}
      {{- $msg = append $msg (printf "The collector \"%s\" is using an unknown preset: %s" $.collectorName $preset) }}
      {{- $msg = append $msg (printf "Please use one of the known presets: %s" (include "english_list_or" $allPresets)) }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
    {{- range $fileName, $_ := $files }}
      {{- $presetValues = merge $presetValues ($.Files.Get $fileName | fromYaml) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $clusterNameValues := dict }}
{{- $clusteringEnabled := or (dig "alloy" "clustering" "enabled" false $namedDefaultValues) (dig "alloy" "clustering" "enabled" false $userValues) (dig "alloy" "clustering" "enabled" false $presetValues) }}
{{- if $clusteringEnabled }}
  {{- $clusterNameSet := or (dig "alloy" "clustering" "name" "" $namedDefaultValues) (dig "alloy" "clustering" "name" "" $userValues) }}
  {{- if not $clusterNameSet }}
    {{- $clusterNameValues = dict "alloy" (dict "clustering" (dict "name" .collectorName))}}
  {{- end }}
{{- end }}
{{ mergeOverwrite $defaultValues $namedDefaultValues $presetValues $globalValues $userCommonValues $clusterNameValues $userValues | toYaml }}
{{- end }}

{{- /* Gets the Alloy values including default upstream values. Input: $, .collectorName (string, collector name), .collectorValues (object) */ -}}
{{- define "collector.alloy.valuesWithUpstream" }}
  {{- /* Values from upstream Alloy */}}
  {{- $upstreamValues := "collectors/upstream/alloy-values.yaml" | .Files.Get | fromYaml }}
  {{- mergeOverwrite $upstreamValues (include "collector.alloy.values" . | fromYaml) | toYaml }}
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
- annotations
- enabled
- extraConfig
- extraService
- labels
- includeDestinations
- liveDebugging
- logging
- presets
- remoteConfig
{{- end }}

{{/* Inputs: . (root object), featureKey (string) */}}
{{ define "collectors.getCollectorForFeature" }}
{{- $collectorName := dig "collector" "" (get .Values .featureKey) }}
{{- if not $collectorName }}
  {{- $collectorName = include (printf "features.%s.chooseCollector" $.featureKey) $ | trim }}
{{- end }}
{{- if not $collectorName }}
  {{- if eq (keys .Values.collectors | len) 1 }}
    {{- $collectorName = (index (keys .Values.collectors) 0) }}
  {{- end }}
{{- end }}
{{- $collectorName }}
{{- end }}

{{ define "collectors.getAllPresets" }}
  {{- range $presetFile, $_ := $.Files.Glob "collectors/presets/*.yaml" }}
- {{ base $presetFile | trimSuffix (ext $presetFile) | trim }}
  {{- end }}
{{- end }}
