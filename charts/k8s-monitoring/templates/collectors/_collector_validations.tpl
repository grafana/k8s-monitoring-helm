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

{{/* Fails when the chart will render Alloy components that require a higher stability.level
     than the collector hosting them is configured for. Walks enabled features, looks up each
     feature's assigned collector and the destinations it forwards to, and -- for each trigger
     declared in collectors.experimentalStabilityRequirements -- raises the minimum required
     stabilityLevel on the affected collector. Inputs: Values, Files. */}}
{{- define "collectors.validate.experimentalStabilityLevel" }}
{{- $root := . }}
{{- $requirements := include "collectors.experimentalStabilityRequirements" . | fromYaml }}
{{- $rank := dict "generally-available" 0 "public-preview" 1 "experimental" 2 }}
{{- $nhcbRequired := dig "nhcbConversion" "stabilityLevel" "" $requirements }}
{{- $rwv2Required := dig "remoteWriteV2" "stabilityLevel" "" $requirements }}
{{- $convertNhcb := and $root.Values.global $root.Values.global.convertClassicHistogramsToNhcb }}
{{- $collectorReasons := dict }}
{{- $collectorMaxRequired := dict }}
{{- range $featureKey := include "features.list.enabled" . | fromYamlArray }}
  {{- /* selfReporting is a chart-internal feature whose collector is chosen by the chart, not the user.
         Skip it here so the validation only fires on collectors wired through a user-facing feature. */}}
  {{- $collectorName := "" }}
  {{- if ne $featureKey "selfReporting" }}
    {{- $collectorName = include "collectors.getCollectorForFeature" (dict "Values" $root.Values "Files" $root.Files "Subcharts" $root.Subcharts "featureKey" $featureKey) }}
  {{- end }}
  {{- if $collectorName }}
    {{- $featureDestinations := include (printf "features.%s.destinations" $featureKey) $root | fromYamlArray }}
    {{- range $destinationName := $featureDestinations }}
      {{- $destination := get $root.Values.destinations $destinationName }}
      {{- if eq (default "" $destination.type) "prometheus" }}
        {{- /* Trigger: prometheus.remote_write protobuf v2 message */}}
        {{- if and $rwv2Required (eq (int (default 1 $destination.remoteWriteProtocol)) 2) }}
          {{- $reason := printf "feature %q forwards to destinations.%s, which uses remoteWriteProtocol: 2 and renders `protobuf_message = \"io.prometheus.write.v2.Request\"` on prometheus.remote_write (Alloy exposes this only at stability.level=%s)" $featureKey $destinationName $rwv2Required }}
          {{- $existing := default list (get $collectorReasons $collectorName) }}
          {{- if not (has $reason $existing) }}
            {{- $_ := set $collectorReasons $collectorName (append $existing $reason) }}
          {{- end }}
          {{- $curMax := default "generally-available" (get $collectorMaxRequired $collectorName) }}
          {{- if gt (int (get $rank $rwv2Required)) (int (get $rank $curMax)) }}
            {{- $_ := set $collectorMaxRequired $collectorName $rwv2Required }}
          {{- end }}
        {{- end }}
        {{- /* Trigger: convert_classic_histograms_to_nhcb on prometheus.scrape */}}
        {{- if and $convertNhcb $nhcbRequired }}
          {{- $reason := printf "feature %q forwards to a prometheus destination (%s) and global.convertClassicHistogramsToNhcb: true renders `convert_classic_histograms_to_nhcb = true` on its scrape components (Alloy exposes this only at stability.level=%s)" $featureKey $destinationName $nhcbRequired }}
          {{- $existing := default list (get $collectorReasons $collectorName) }}
          {{- if not (has $reason $existing) }}
            {{- $_ := set $collectorReasons $collectorName (append $existing $reason) }}
          {{- end }}
          {{- $curMax := default "generally-available" (get $collectorMaxRequired $collectorName) }}
          {{- if gt (int (get $rank $nhcbRequired)) (int (get $rank $curMax)) }}
            {{- $_ := set $collectorMaxRequired $collectorName $nhcbRequired }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- range $collectorName, $reasons := $collectorReasons }}
  {{- $required := get $collectorMaxRequired $collectorName }}
  {{- $collectorValues := include "collector.alloy.values" (dict "Values" $root.Values "Files" $root.Files "collectorName" $collectorName) | fromYaml }}
  {{- /* collectorCommon.alloy.<k> currently lands at the top level of collectorValues rather than under
         collectorValues.alloy, so look in both places before deciding the user hasn't set it. */}}
  {{- $stability := dig "alloy" "stabilityLevel" (dig "stabilityLevel" "generally-available" $collectorValues) $collectorValues }}
  {{- $actualRank := int (default 0 (get $rank $stability)) }}
  {{- $requiredRank := int (get $rank $required) }}
  {{- if lt $actualRank $requiredRank }}
    {{- $msg := list "" }}
    {{- $msg = append $msg (printf "Collector %q has stabilityLevel=%q but the chart will render Alloy components that require stabilityLevel=%s:" $collectorName $stability $required) }}
    {{- range $r := $reasons }}
      {{- $msg = append $msg (printf "  - %s" $r) }}
    {{- end }}
    {{- $msg = append $msg "" }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "collectors:" }}
    {{- $msg = append $msg (printf "  %s:" $collectorName) }}
    {{- $msg = append $msg "    alloy:" }}
    {{- $msg = append $msg (printf "      stabilityLevel: %s" $required) }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}

{{/* The set of Alloy components / arguments the chart can render today that are not yet
     generally-available, mapped to the minimum stability.level Alloy currently exposes them at.
     Update an entry when Alloy graduates the component
     (`experimental` → `public-preview` → `generally-available`). Set the level to
     `generally-available` (or delete the entry) to remove the requirement entirely. */}}
{{- define "collectors.experimentalStabilityRequirements" }}
# Triggered by global.convertClassicHistogramsToNhcb: true on any feature that forwards to a
# prometheus destination. Renders `convert_classic_histograms_to_nhcb = true` on the
# prometheus.scrape components the feature emits.
nhcbConversion:
  stabilityLevel: experimental
# Triggered by any prometheus destination with remoteWriteProtocol: 2. Renders
# `protobuf_message = "io.prometheus.write.v2.Request"` on prometheus.remote_write.
remoteWriteV2:
  stabilityLevel: experimental
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
