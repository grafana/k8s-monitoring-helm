{{/* Inputs: collectorValues (collector name), portNumber */}}
{{- define "collectors.hasExtraPort" -}}
{{- $extraPorts := deepCopy (dig "alloy" "extraPorts" list .collectorValues) }}
{{- $found := "false" -}}
{{- range $portEntry := $extraPorts -}}
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

{{/* Inputs: collectorValues (collector values), featureName (feature name), portNumber, portName, portProtocol */}}
{{- define "collectors.requireExtraPort" }}
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
    {{- $name := include "helper.kubernetesName" (default .collectorName .Values.nameOverride) }}
    {{- if contains $name .Release.Name }}
      {{- .Release.Name | trunc 63 | trimSuffix "-" }}
    {{- else }}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Inputs: Values (all values), collectorName (collector name), collectorValues (collector values, if not inside `.Values.collectors` map) */}}
{{- define "collector.alloy.serviceAccountName" }}
{{- $collectorValues := include "collector.alloy.values" . | fromYaml }}
{{- if dig "serviceAccount" "create" true $collectorValues }}
  {{- dig "serviceAccount" "name" "" $collectorValues | default (include "collector.alloy.fullname" .) }}
{{- else }}
  {{- dig "serviceAccount" "name" "" $collectorValues | default "default" }}
{{- end }}
{{- end }}

{{- define "collector.alloy.labels" }}
helm.sh/chart: {{ include "helper.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: alloy
{{- end }}

{{- define "collector.alloy.selectorLabels" }}
app.kubernetes.io/name: {{ include "helper.kubernetesName" .collectorName }}
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
{{- if dig "image" "pullPolicy" "" .Values.global }}
  {{- $globalValues = mergeOverwrite $globalValues (dict "global" (dict "image" (dict "pullPolicy" .Values.global.image.pullPolicy))) }}
{{- end }}
{{- if dig "podSecurityContext" "" .Values.global }}
  {{- $globalValues = mergeOverwrite $globalValues (dict "global" (dict "podSecurityContext" .Values.global.podSecurityContext)) }}
{{- end }}
{{- $globalValues | toYaml }}
{{- end }}

{{- /* Returns the list found at .path (a list of keys) within .source, or an empty list. Output: a YAML array.
       Inputs: .source (map), .path (list of string keys). */ -}}
{{- define "collector.alloy.digPath" -}}
{{- $node := .source -}}
{{- range $key := .path -}}
  {{- if kindIs "map" $node -}}
    {{- $node = index $node $key -}}
  {{- end -}}
{{- end -}}
{{- $node | default (list) | toYaml -}}
{{- end }}

{{- /* Builds a nested map from .path (a list of keys) wrapping .value. Output: YAML.
       Inputs: .value (any), .path (list of string keys). */ -}}
{{- define "collector.alloy.nestPath" -}}
{{- $nested := .value -}}
{{- range $key := reverse .path -}}
  {{- $nested = dict $key $nested -}}
{{- end -}}
{{- $nested | toYaml -}}
{{- end }}

{{- /* The preset value lists that should be appended across presets rather than overwritten by Helm's merge.
       Each entry is the key-path to a list. Add a path here to make another preset list additive. Output: a YAML
       array of key-paths. */ -}}
{{- define "collector.alloy.appendablePaths" -}}
- ["alloy", "extraPorts"]
- ["alloy", "mounts", "extra"]
- ["controller", "volumes", "extra"]
- ["controller", "initContainers"]
{{- end }}

{{- /* Gets the Alloy values. Input: $, .collectorName (string, collector name), .collectorValues (object) */ -}}
{{- define "collector.alloy.values" }}
{{- /* The default settings set for all Alloy instances by this chart */}}
{{- $defaultValues := "collectors/alloy-values.yaml" | .Files.Get | fromYaml }}
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
{{- $appendablePaths := include "collector.alloy.appendablePaths" . | fromYamlArray }}
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
      {{- $presetFile := $.Files.Get $fileName | fromYaml }}
      {{- /* Helm's merge overwrites lists, so for each appendable path concatenate this preset's entries onto what
             earlier presets contributed. */}}
      {{- range $path := $appendablePaths }}
        {{- $incoming := include "collector.alloy.digPath" (dict "source" $presetFile "path" $path) | fromYamlArray }}
        {{- if $incoming }}
          {{- $existing := include "collector.alloy.digPath" (dict "source" $presetValues "path" $path) | fromYamlArray }}
          {{- $presetValues = mergeOverwrite $presetValues (include "collector.alloy.nestPath" (dict "value" (concat $existing $incoming) "path" $path) | fromYaml) }}
        {{- end }}
      {{- end }}
      {{- $presetValues = merge $presetValues $presetFile }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $clusterNameValues := dict }}
{{- $clusteringEnabled := or (dig "alloy" "clustering" "enabled" false $userValues) (dig "alloy" "clustering" "enabled" false $presetValues) }}
{{- if $clusteringEnabled }}
  {{- $clusterNameSet := dig "alloy" "clustering" "name" "" $userValues }}
  {{- if not $clusterNameSet }}
    {{- $clusterNameValues = dict "alloy" (dict "clustering" (dict "name" .collectorName))}}
  {{- end }}
{{- end }}
{{- /* When this chart does not deploy the Alloy Operator, an external (possibly older) operator reconciles these
       instances and would otherwise choose the Alloy image itself. Pin the Alloy image tag to the version this
       chart expects. This is a low-precedence default (applied before presets and user values), so a preset such
       as `windows` or a user-set image tag still wins. */}}
{{- $operatorImageValues := dict }}
{{- if not (index $.Values "alloy-operator").deploy }}
  {{- $operatorImageValues = dict "image" (dict "tag" (include "collector.alloy.pinnedImageTag" .)) }}
{{- end }}
{{ mergeOverwrite $defaultValues $operatorImageValues $presetValues (deepCopy $globalValues) (deepCopy $userCommonValues) $clusterNameValues (deepCopy $userValues) | toYaml }}
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
{{- $subchart := include "features.subchartName" .featureKey }}
{{- $subfeature := include "features.subfeatureName" .featureKey -}}
{{- $featureValues := (get .Values $subchart) }}

{{- $collectorName := (dig $subfeature "collector" "" $featureValues) | default (get $featureValues "collector") }}

{{- if and (not $collectorName) (eq .featureKey "selfReporting") }}
  {{- $collectorName = include "features.selfReporting.chooseCollector" $ | trim }}
{{- end }}

{{- if not $collectorName }}
  {{- $enabledCollectors := include "collectors.list.enabled" . | fromYamlArray }}
  {{- if eq (len $enabledCollectors) 1 }}
    {{- $collectorName = first $enabledCollectors }}
  {{- end }}
{{- end }}
{{- $collectorName }}
{{- end }}

{{- define "collectors.getCollectorForIntegrationInstance" -}}
{{- $instanceCollector := dig "collector" "" .instance -}}
{{- if $instanceCollector -}}
{{- $instanceCollector -}}
{{- else -}}
{{- include "collectors.getCollectorForFeature" (dict "Values" .Values "Files" .Files "Subcharts" .Subcharts "featureKey" "integrations") | trim -}}
{{- end -}}
{{- end -}}

{{- define "collectors.getCollectorsForFeature" -}}
{{- $collectors := list -}}
{{- if eq .featureKey "integrations" -}}
{{- $collectors = include "collectors.integrations.assignedCollectors" . | fromYamlArray -}}
{{- end -}}
{{- if not $collectors -}}
{{- $collectorName := include "collectors.getCollectorForFeature" . | trim -}}
{{- if $collectorName -}}
{{- $collectors = list $collectorName -}}
{{- end -}}
{{- end -}}
{{- range $collectorName := $collectors }}
- {{ $collectorName }}
{{- end -}}
{{- end -}}

{{ define "collectors.getAllPresets" }}
  {{- range $presetFile, $_ := $.Files.Glob "collectors/presets/*.yaml" }}
- {{ base $presetFile | trimSuffix (ext $presetFile) | trim }}
  {{- end }}
{{- end }}

{{/* Lists the names of enabled collectors. Collectors default to enabled unless `enabled: false` is set. Input: . (root) */}}
{{- define "collectors.list.enabled" }}
{{- range $collectorName := keys (.Values.collectors | default dict) | sortAlpha }}
  {{- if dig "enabled" true (get ($.Values.collectors | default dict) $collectorName | default dict) }}
- {{ $collectorName }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Renders a single collector's Alloy config up to (but not including) replaceComponent substitution
     and trailing-whitespace trimming. This is the shared source of truth used by both
     templates/alloy-config.yaml (the collector ConfigMap) and the config-validator pre-install hook.
     Each caller applies replaceComponent and the final whitespace trim itself — alloy-config.yaml also
     tracks replacement usage for its "unused replacement" validation — so the validated config stays
     byte-identical to the deployed config. Input: the per-collector context dict built in
     alloy-config.yaml, i.e. a dict with keys Values, Chart, Files, Release, Subcharts, Template,
     Capabilities and collectorName. */}}
{{- define "collector.alloy.config" -}}
{{- $collectorName := .collectorName }}
{{- $destinationNames := (get $.Values.collectors $collectorName).includeDestinations | default list }}
{{- range $featureKey := include "features.list" $ | fromYamlArray }}
  {{- $featureCollectorNames := include "collectors.getCollectorsForFeature" (dict "Values" $.Values "Files" $.Files "Subcharts" $.Subcharts "featureKey" $featureKey) | fromYamlArray }}
  {{- if has $collectorName $featureCollectorNames }}
    {{- $destinationNames = concat $destinationNames ((include (printf "features.%s.destinations" $featureKey) $) | fromYamlArray) }}
  {{- end }}
{{- end }}
{{- /* Router destination type. Any enabled `type: router` destination that ended up in
       $destinationNames (because a feature pointed at it) fans out to real destinations that are
       never referenced by a feature directly, so those downstream destinations would otherwise
       never get a body rendered and the router's gates would dangle. Union them in here, before
       destinations.alloy.config renders bodies below. Single-level only: a router referencing
       another router is not resolved transitively by this pass. */}}
{{- range $routerCandidateName := $destinationNames }}
  {{- if hasKey $.Values.destinations $routerCandidateName }}
    {{- $routerCandidate := get $.Values.destinations $routerCandidateName }}
    {{- if and (eq $routerCandidate.type "router") (not $routerCandidate.disabled) }}
      {{- range $downstreamName := ($routerCandidate.defaultDestinations | default list) }}
        {{- if and (hasKey $.Values.destinations $downstreamName) (not (get $.Values.destinations $downstreamName).disabled) }}
          {{- $destinationNames = append $destinationNames $downstreamName }}
        {{- end }}
      {{- end }}
      {{- range $route := ($routerCandidate.routes | default list) }}
        {{- range $downstreamName := ($route.destinations | default list) }}
          {{- if and (hasKey $.Values.destinations $downstreamName) (not (get $.Values.destinations $downstreamName).disabled) }}
            {{- $destinationNames = append $destinationNames $downstreamName }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $collectorValues := include "collector.alloy.values" $ | fromYaml }}
{{- $alloyConfig := "" }}
{{- range $featureKey := include "features.list" $ | fromYamlArray }}
  {{- $featureCollectorNames := include "collectors.getCollectorsForFeature" (dict "Values" $.Values "Files" $.Files "Subcharts" $.Subcharts "featureKey" $featureKey) | fromYamlArray }}
  {{- if has $collectorName $featureCollectorNames }}
    {{- $featureConfig := include (printf "features.%s.include" $featureKey) $ | trim }}
    {{- if $featureConfig }}
      {{- $alloyConfig = cat $alloyConfig ($featureConfig | nindent 0) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $dataProcessorSharedComponents := include "dataProcessors.alloy.collectorComponents" (dict "Values" $.Values "config" $alloyConfig) | trim }}
{{- if $dataProcessorSharedComponents }}
  {{- $alloyConfig = cat $alloyConfig ($dataProcessorSharedComponents | nindent 0) }}
{{- end }}
{{- $alloyConfig = cat $alloyConfig (include "collectors.logging.alloy" $collectorValues | trim | nindent 0) }}
{{- $alloyConfig = cat $alloyConfig (include "collectors.liveDebugging.alloy" $collectorValues | trim | nindent 0) }}
{{- $alloyConfig = cat $alloyConfig (include "collectors.remoteConfig.alloy" $ | trim | nindent 0) }}
{{- $alloyConfig = cat $alloyConfig (include "collectors.extraConfig.alloy" $ | trim | nindent 0) }}
{{- $alloyConfig = cat $alloyConfig (include "destinations.alloy.rules" (deepCopy $ | merge (dict "collectorName" $collectorName)) | trim | nindent 0) }}
{{- $alloyConfig = cat $alloyConfig (include "destinations.alloy.config" (deepCopy $ | merge (dict "destinationNames" ($destinationNames | uniq | sortAlpha))) | trim | nindent 0) }}
{{- $alloyConfig }}
{{- end }}
