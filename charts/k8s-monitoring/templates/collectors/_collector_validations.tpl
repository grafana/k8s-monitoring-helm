{{/* Inputs: Values (root Values), collectorName (string), featureKey (string), featureName (string) */}}
{{- define "collectors.validate.collectorIsAssigned" }}
{{- $allCollectors := include "collectors.list.enabled" . | fromYamlArray }}
{{- if not .collectorName }}
  {{- $msg := list "" (printf "The %s feature requires a collector to be assigned." .featureName) }}
  {{- $msg = append $msg "Please assign one by setting the following:" }}
  {{- $msg = append $msg (printf "%s:" .featureKey) }}
  {{- $msg = append $msg (printf "  collector: %s" (include "english_list_or" $allCollectors)) }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- if not (has .collectorName $allCollectors) }}
  {{- $msg := list "" (printf "The %s feature wants to use a collector named \"%s\", but that collector does not exist or is disabled." .featureName .collectorName) }}
  {{- $msg = append $msg "Please assign one by setting the following:" }}
  {{- $msg = append $msg (printf "%s:" .featureKey) }}
  {{- $msg = append $msg (printf "  collector: %s" (include "english_list_or" $allCollectors)) }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{- define "collectors.validate.featuresEnabled" }}
{{- $collectorsUtilized := list }}
{{- range $featureKey := include "features.list.enabled" . | fromYamlArray }}
  {{- $assignedCollector := include "collectors.getCollectorForFeature" (dict "Values" $.Values "Files" $.Files "Subcharts" $.Subcharts "featureKey" $featureKey) }}
  {{- $collectorsUtilized = append $collectorsUtilized $assignedCollector }}
{{- end }}

{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
  {{- $usedByAFeature := has $collectorName $collectorsUtilized }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) | fromYaml }}
  {{- $extraConfigDefined := not (not $collectorValues.extraConfig) }}
  {{- $remoteConfigEnabled := $collectorValues.remoteConfig.enabled }}
  {{- if not (or $usedByAFeature $extraConfigDefined $remoteConfigEnabled) }}
    {{- $msg := list "" (printf "The %s collector is enabled, but there are no enabled features that will use it." $collectorName) }}
    {{- $msg = append $msg "Please disable the collector by removing it from the collectors list or by setting:" }}
    {{- $msg = append $msg "collectors:" }}
    {{- $msg = append $msg (printf "  %s:" $collectorName) }}
    {{- $msg = append $msg "    enabled: false" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Inputs: Values (root Values), Files, collectorName (string), featureName (string) */}}
{{- define "collectors.validate.clusteringEnabled" }}
{{- if .collectorName }}
  {{- $collectorValues := include "collector.alloy.valuesWithUpstream" (dict "Values" .Values "Files" .Files "collectorName" .collectorName) | fromYaml }}
  {{- $controllerType := dig "controller" "type" "daemonset" $collectorValues }}
  {{- $replicas := dig "controller" "replicas" 1 $collectorValues }}
  {{- $hpaEnabled := or (dig "controller" "autoscaling" "enabled" false $collectorValues) (dig "controller" "autoscaling" "horizontal" "enabled" false $collectorValues) }}
  {{- if or (eq $controllerType "daemonset") (gt (int $replicas) 1) $hpaEnabled }}
    {{- if not (dig "alloy" "clustering" "enabled" false $collectorValues) }}
      {{- $msg := list "" (printf "The %s feature requires clustering to be enabled on the %s collector." .featureName .collectorName) }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    presets: [clustered]" }}
      {{- $msg = append $msg "OR"}}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    alloy:"}}
      {{- $msg = append $msg "      clustering:"}}
      {{- $msg = append $msg "        enabled: true" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Fails if the collector's stability level is too restrictive for the components in its rendered config.
     The experimental and public-preview component lists are the same files used by scripts/lint-alloy.sh,
     so the linter and the chart validation stay in sync.
     Inputs: collectorName (string), config (assembled Alloy config), collectorValues (merged collector values), Files */}}
{{- define "collectors.validate.stabilityLevel" }}
  {{- $configuredLevel := dig "alloy" "stabilityLevel" "generally-available" .collectorValues }}
  {{- if ne $configuredLevel "experimental" }}
    {{- $offenders := list }}
    {{- $needsExperimental := false }}
    {{- $experimentalComponents := .Files.Get "collectors/alloy-experimental.yaml" | fromYamlArray }}
    {{- range $component := $experimentalComponents }}
      {{- $pattern := printf "(?m)^[[:space:]]*%s[[:space:]]" ($component | replace "." "\\.") }}
      {{- if regexMatch $pattern $.config }}
        {{- $offenders = append $offenders (printf "  - %s (experimental)" $component) }}
        {{- $needsExperimental = true }}
      {{- end }}
    {{- end }}

    {{- if ne $configuredLevel "public-preview" }}
      {{- $publicPreviewComponents := .Files.Get "collectors/alloy-public-preview.yaml" | fromYamlArray }}

      {{- range $component := $publicPreviewComponents }}
        {{- $pattern := printf "(?m)^[[:space:]]*%s[[:space:]]" ($component | replace "." "\\.") }}
        {{- if regexMatch $pattern $.config }}
          {{- $offenders = append $offenders (printf "  - %s (public-preview)" $component) }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- if $offenders }}
      {{- $requiredLevel := "public-preview" }}
      {{- $requiredPhrase := "\"public-preview\" or \"experimental\"" }}
      {{- if $needsExperimental }}
        {{- $requiredLevel = "experimental" }}
        {{- $requiredPhrase = "\"experimental\"" }}
      {{- end }}
      {{- $msg := list "" }}
      {{- if eq (len $offenders) 1 }}
        {{- $msg = append $msg (printf "The Alloy collector %q is using a component which is not available in its current stability level (%s):" .collectorName $configuredLevel) }}
      {{- else }}
        {{- $msg = append $msg (printf "The Alloy collector %q is using these components which are not available in its current stability level (%s):" .collectorName $configuredLevel) }}
      {{- end }}
      {{- $msg = concat $msg $offenders }}
      {{- $msg = append $msg "" }}
      {{- $msg = append $msg (printf "Please set the stability level to %s to use this configuration, or adjust the configuration to remove these components." $requiredPhrase) }}
      {{- $msg = append $msg "" }}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    alloy:" }}
      {{- $msg = append $msg (printf "      stabilityLevel: %s" $requiredLevel) }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "collectors.validate.atLeastOneEnabled" }}
  {{- $enabledCollectors := include "collectors.list.enabled" . | fromYamlArray }}
  {{- if eq (len $enabledCollectors) 0 }}
    {{- $msg := list "" "At least one collector should be enabled" }}
    {{- $msg = append $msg "Please enable one by setting:" }}
    {{- $msg = append $msg "collectors:" }}
    {{- $msg = append $msg "  <collector-name>:" }}
    {{- $msg = append $msg "    <collector-settings>" }}
    {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/collectors/README.md for more details." }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}

{{/* Fails if the deprecated "privileged" preset is combined with the targeted presets that replace it. */}}
{{- define "collectors.validate.deprecatedPrivilegedPreset" }}
  {{- range $collectorName, $collector := (.Values.collectors | default dict) }}
    {{- $presets := dig "presets" (list) ($collector | default dict) }}
    {{- if and (has "privileged" $presets) (or (has "root" $presets) (has "host-network" $presets)) }}
      {{- $msg := list "" (printf "The %s collector combines the deprecated \"privileged\" preset with the \"root\" or \"host-network\" preset." $collectorName) }}
      {{- $msg = append $msg "The \"privileged\" preset is deprecated and cannot be combined with the \"root\" or \"host-network\" presets." }}
      {{- $msg = append $msg "Replace \"privileged\" with \"root\" (which sets the same securityContext) and add the host presets you need. For example:" }}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" $collectorName) }}
      {{- $msg = append $msg "    presets: [root, host-network, host-storage, host-cgroup, host-tracefs]" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Fails if two collector keys normalize to the same Kubernetes-safe name (e.g. alloyMetrics and alloymetrics). */}}
{{- define "collectors.validate.uniqueNames" }}
  {{- $byNormalized := dict }}
  {{- range $collectorName := keys (.Values.collectors | default dict) | sortAlpha }}
    {{- $normalized := include "helper.kubernetesName" $collectorName | trim }}
    {{- $existing := index $byNormalized $normalized | default list }}
    {{- $_ := set $byNormalized $normalized (append $existing $collectorName) }}
  {{- end }}
  {{- range $normalized, $collectorNames := $byNormalized }}
    {{- if gt (len $collectorNames) 1 }}
      {{- $msg := list "" (printf "Multiple collectors resolve to the same Kubernetes resource name %q: %s" $normalized (join ", " $collectorNames)) }}
      {{- $msg = append $msg "Collector names are normalized to lowercase DNS-1123 names when used as Kubernetes resource names, so they must be unique after normalization." }}
      {{- $msg = append $msg "Please rename all but one of these collectors." }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Inputs: . (root object), collectorName (string), featureKey (string) */}}
{{- define "collectors.validate.exists" }}
  {{- if .collectorName }}
    {{- $collectors := keys (.Values.collectors | default dict) | sortAlpha }}
    {{- if not (has .collectorName $collectors) }}
      {{- $msg := list "" (printf "The feature %s is referencing a collector named %q but it does not exist." .featureKey .collectorName) }}
      {{- $msg = append $msg "Please assign the feature to one of these collectors:" }}
      {{- $msg = append $msg (printf "%s:" .featureKey) }}
      {{- $msg = append $msg (printf "  collector: %s" (include "english_list_or" $collectors)) }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
