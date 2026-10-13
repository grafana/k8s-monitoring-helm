{{/* Inputs: . (map). Output: "true" if any value is true */}}
{{- define "collectors.rbac.anyEnabled" -}}
{{- $found := false -}}
{{- range $_, $value := (. | default dict) -}}
  {{- if and (kindIs "bool" $value) $value }}{{ $found = true }}{{ end -}}
{{- end -}}
{{- $found -}}
{{- end }}

{{/* Inputs: . (root with collectorName), featureKeys, destinationNames, alloyValues (optional) */}}
{{- define "collectors.rbac.entries" -}}
{{- $featuresWithRules := list "annotationAutodiscovery" "applicationObservability" "autoInstrumentation" "clusterEvents" "clusterMetrics" "costMetrics" "hostMetrics_energyMetrics" "hostMetrics_linuxHosts" "hostMetrics_windowsHosts" "integrations" "kubernetesManifests" "podLogsObjects" "podLogsViaKubernetesApi" "podLogsViaLoki" "podLogsViaOpenTelemetry" "profiling" "prometheusOperatorObjects" }}
{{- $entries := list }}
{{- range $featureKey := .featureKeys }}
  {{- if has $featureKey $featuresWithRules }}
    {{- $entries = concat $entries (include (printf "features.%s.rbac" $featureKey) $ | fromYamlArray) }}
  {{- end }}
{{- end }}
{{- $entries = concat $entries (include "collectors.rbac.secretEntries" $ | fromYamlArray) }}
{{- $entries = concat $entries (include "collectors.rbac.destinationEntries" $ | fromYamlArray) }}
{{- $entries = concat $entries (include "collectors.rbac.dataProcessorEntries" $ | fromYamlArray) }}
{{- $entries = concat $entries (include "collectors.rbac.sdkInjectorEntries" $ | fromYamlArray) }}
{{- $entries | toYaml }}
{{- end }}

{{/* Inputs: . (root), destination (with defaults), destinationName */}}
{{- define "collectors.rbac.secretEntry" -}}
{{- $secretArgs := dict "Values" .Values "Chart" .Chart "Release" .Release "object" .destination "name" .destinationName }}
{{- dict "bundle" "secret" "namespaces" (list (include "secrets.kubernetesSecretNamespace" $secretArgs)) "resourceNames" (list (include "secrets.kubernetesSecretName" $secretArgs)) | toYaml }}
{{- end }}

{{/* Inputs: . (root), destinationNames */}}
{{- define "collectors.rbac.secretEntries" -}}
{{- $entries := list }}
{{- range $destinationName := .destinationNames }}
  {{- $destination := get $.Values.destinations $destinationName }}
  {{- if $destination }}
    {{- $destination = mergeOverwrite ((printf "destinations/%s-values.yaml" $destination.type) | $.Files.Get | fromYaml) $destination }}
    {{- if eq (include "secrets.usesKubernetesSecret" $destination) "true" }}
      {{- $entries = append $entries (include "collectors.rbac.secretEntry" (merge (dict "destination" $destination "destinationName" $destinationName) $) | fromYaml) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $entries | toYaml }}
{{- end }}

{{/* Separate from collectors.rbac.secretEntries, which sampler and service graph instances use without these. Inputs: . (root with collectorName), destinationNames */}}
{{- define "collectors.rbac.destinationEntries" -}}
{{- $entries := list }}
{{- $releaseNamespace := include "helper.namespace" $ }}
{{- range $destinationName := .destinationNames }}
  {{- $destination := get $.Values.destinations $destinationName }}
  {{- if $destination }}
    {{- $destination = mergeOverwrite ((printf "destinations/%s-values.yaml" $destination.type) | $.Files.Get | fromYaml) $destination }}
    {{- if eq $destination.type "prometheus" }}
      {{- if or (dig "metricEnrichment" "podLabels" list $destination) (dig "metricEnrichment" "namespaceLabels" list $destination) }}
        {{- $entries = append $entries (dict "bundle" "pods") }}
      {{- end }}
      {{- if dig "metricEnrichment" "namespaceLabels" list $destination }}
        {{- $entries = append $entries (dict "bundle" "namespaces") }}
      {{- end }}
    {{- else if eq $destination.type "otlp" }}
      {{- $sendsToSampler := and (eq (include "destinations.otlp.isTailSamplingEnabled" $destination) "true") (eq (dig "processors" "tailSampling" "loadBalancer" "resolver" "kubernetes" $destination) "kubernetes") }}
      {{- $sendsToServiceGraph := and (eq (include "destinations.otlp.isServiceGraphsEnabled" $destination) "true") (eq (dig "processors" "serviceGraphMetrics" "loadBalancer" "resolver" "kubernetes" $destination) "kubernetes") }}
      {{- if or $sendsToSampler $sendsToServiceGraph }}
        {{- $entries = append $entries (dict "bundle" "loadBalancer" "namespaces" (list $releaseNamespace)) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- /* Rules are synchronized by a single collector per destination, like destinations.prometheus.rules.alloy. */}}
{{- range $destinationName, $destination := (include "destinations.getEnabled" $.Values.destinations | fromYaml) }}
  {{- if eq $destination.type "prometheus" }}
    {{- $destination = mergeOverwrite ("destinations/prometheus-values.yaml" | $.Files.Get | fromYaml) $destination }}
    {{- if dig "rules" "enabled" false $destination }}
      {{- $rulesCollector := $destination.rules.collector }}
      {{- if not $rulesCollector }}
        {{- $rulesCollector = include "collectors.list.enabled" $ | fromYamlArray | first }}
      {{- end }}
      {{- if eq $rulesCollector $.collectorName }}
        {{- $entries = append $entries (dict "bundle" "prometheusRules") }}
        {{- if eq (include "secrets.usesKubernetesSecret" $destination) "true" }}
          {{- $entries = append $entries (include "collectors.rbac.secretEntry" (merge (dict "destination" $destination "destinationName" $destinationName) $) | fromYaml) }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $entries | toYaml }}
{{- end }}

{{/* Inputs: . (root), featureKeys */}}
{{- define "collectors.rbac.dataProcessorNames" -}}
{{- $names := list }}
{{- range $featureKey := .featureKeys | default list }}
  {{- if eq (include (printf "features.%s.enabled" $featureKey) $) "true" }}
    {{- range $name := dig "dataProcessors" list (get $.Values (include "features.subchartName" $featureKey) | default dict) }}
      {{- if hasKey ($.Values.dataProcessors | default dict) $name }}
        {{- $names = append $names $name }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $names | uniq | sortAlpha | toYaml }}
{{- end }}

{{/* Inputs: . (root), featureKeys */}}
{{- define "collectors.rbac.dataProcessorEntries" -}}
{{- $entries := list }}
{{- range $name := include "collectors.rbac.dataProcessorNames" $ | fromYamlArray }}
  {{- if eq (get $.Values.dataProcessors $name).type "kubernetesEnrichment" }}
    {{- $entries = append $entries (dict "bundle" "pods") }}
    {{- $entries = append $entries (dict "bundle" "namespaces") }}
    {{- $entries = append $entries (dict "bundle" "k8sattributes") }}
  {{- end }}
{{- end }}
{{- $entries | toYaml }}
{{- end }}

{{/* The SDK Injector only accepts ConfigMaps from the users in allowedConfigMapWriters. Inputs: . (root with collectorName) */}}
{{- define "collectors.rbac.sdkInjectorEntries" -}}
{{- $entries := list }}
{{- if .Values.telemetryServices.sdkInjector.deploy }}
  {{- $namespace := include "helper.namespace" $ }}
  {{- $serviceAccountName := include "collector.alloy.serviceAccountName" $ }}
  {{- $writers := list }}
  {{- range $writer := splitList "," (.Values.telemetryServices.sdkInjector.allowedConfigMapWriters | default "") }}
    {{- $writers = append $writers (trim $writer) }}
  {{- end }}
  {{- range $writerNamespace := list "$(POD_NAMESPACE)" $namespace }}
    {{- if has (printf "system:serviceaccount:%s:%s" $writerNamespace $serviceAccountName) $writers }}
      {{- $entries = list (dict "bundle" "configMapWriter" "namespaces" (list $namespace)) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $entries | toYaml }}
{{- end }}

{{/* Inputs: . (root), extraConfig (rendered), replacements (matched components), destinationNames, featureKeys, config (final config) */}}
{{- define "collectors.rbac.userConfig" -}}
{{- $texts := list }}
{{- with .extraConfig }}
  {{- $texts = append $texts (dict "source" "extraConfig" "text" .) }}
{{- end }}
{{- range $content := .replacements | default list }}
  {{- $texts = append $texts (dict "source" "replaceComponent" "text" $content) }}
{{- end }}
{{- range $destinationName := .destinationNames | default list }}
  {{- $destination := get $.Values.destinations $destinationName }}
  {{- if and $destination (eq $destination.type "custom") $destination.config }}
    {{- $texts = append $texts (dict "source" (printf "destination %s" $destinationName) "text" $destination.config) }}
  {{- end }}
{{- end }}
{{- range $name := include "collectors.rbac.dataProcessorNames" $ | fromYamlArray }}
  {{- $processor := get $.Values.dataProcessors $name }}
  {{- if eq $processor.type "custom" }}
    {{- range $type, $ecosystems := omit $processor "type" }}
      {{- if kindIs "map" $ecosystems }}
        {{- range $ecosystem, $settings := $ecosystems }}
          {{- if and (kindIs "map" $settings) $settings.config (contains (printf "// Processor: %s (custom) — %s/%s" $name $type $ecosystem) ($.config | default "")) }}
            {{- $texts = append $texts (dict "source" (printf "data processor %s" $name) "text" $settings.config) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $texts | toYaml }}
{{- end }}

{{/* Inputs: body, name. Output: the top-level attribute value, or "" if it isn't set */}}
{{- define "collectors.rbac.attribute" -}}
{{- $list := regexFind (printf `(?m)^\s*%s\s*=\s*\[[^\]]*\]` .name) .body }}
{{- $line := regexFind (printf `(?m)^\s*%s\s*=.*$` .name) .body }}
{{- if $list }}
  {{- regexReplaceAll (printf `(?s)^\s*%s\s*=\s*` .name) $list "" | replace "\n" " " }}
{{- else if $line }}
  {{- regexReplaceAll (printf `^\s*%s\s*=\s*(.*?)\s*(//.*)?$` .name) $line "${1}" }}
{{- end }}
{{- end }}

{{/* Inputs: value (raw attribute value). Output: the string, or "" if the value isn't a single string literal */}}
{{- define "collectors.rbac.literal" -}}
{{- if regexMatch `^"[^"\\]*"$` .value }}{{ trimAll "\"" .value }}{{ end }}
{{- end }}

{{/* Inputs: item, block, body (block without nested blocks), releaseNamespace. Output: {namespaces, unknown} */}}
{{- define "collectors.rbac.scope" -}}
{{- $namespaces := list }}
{{- $unknown := eq (.item.scope | default "") "unknown" }}
{{- $list := "" }}
{{- if eq .item.scope "namespacesBlock" }}
  {{- $nested := regexFind `namespaces\s*\{[^{}]*\}` .block }}
  {{- if $nested }}
    {{- if regexMatch `own_namespace\s*=\s*true` $nested }}
      {{- $namespaces = list .releaseNamespace }}
    {{- end }}
    {{- $list = include "collectors.rbac.attribute" (dict "body" (trimSuffix "}" (regexReplaceAll `^namespaces\s*\{` $nested "")) "name" "names") }}
    {{- if not (or $list $namespaces) }}{{ $unknown = true }}{{ end }}
  {{- end }}
{{- else if eq .item.scope "namespacesAttribute" }}
  {{- $list = include "collectors.rbac.attribute" (dict "body" .body "name" "namespaces") }}
{{- else if eq .item.scope "filterNamespace" }}
  {{- $filter := regexFind `filter\s*\{(?:[^{}]|\{[^{}]*\})*\}` .block }}
  {{- $filterBody := regexReplaceAll `\{[^{}]*\}` (trimSuffix "}" (regexReplaceAll `^filter\s*\{` $filter "")) "{}" }}
  {{- with include "collectors.rbac.attribute" (dict "body" $filterBody "name" "namespace") }}
    {{- $namespace := include "collectors.rbac.literal" (dict "value" .) }}
    {{- if $namespace }}{{ $namespaces = list $namespace }}{{ else }}{{ $unknown = true }}{{ end }}
  {{- end }}
{{- end }}
{{- if $list }}
  {{- if regexMatch `^\[\s*("[^"\\]*"\s*,\s*)*("[^"\\]*"\s*,?\s*)?\]$` $list }}
    {{- range $value := regexFindAll `"[^"\\]*"` $list -1 }}
      {{- $namespaces = append $namespaces (trimAll "\"" $value) }}
    {{- end }}
  {{- else }}
    {{- $unknown = true }}
  {{- end }}
{{- end }}
{{- dict "namespaces" ($namespaces | uniq) "unknown" $unknown | toYaml }}
{{- end }}

{{/* Inputs: components (collectors/alloy-kubernetes-api.yaml), text, releaseNamespace. Output: [{component, entries, requires, anyScope}] */}}
{{- define "collectors.rbac.scan" -}}
{{- $matches := list }}
{{- $text := .text }}
{{- $tick := printf "%c" 96 }}
{{- range $literal := regexFindAll (printf `"(?:[^"\\]|\\.)*"|%s[^%s]*%s|//[^\n]*|/\*(?s:.*?)\*/` $tick $tick $tick) .text -1 }}
  {{- if regexMatch `[{}]` $literal }}
    {{- $text = replace $literal ($literal | replace "{" "(" | replace "}" ")") $text }}
  {{- end }}
{{- end }}
{{- $nested := `[^{}]*` }}
{{- range $_ := until 8 }}
  {{- $nested = printf `(?:[^{}]|\{%s\})*` $nested }}
{{- end }}
{{- range $item := .components }}
  {{- if $item.pattern }}
    {{- if regexMatch (printf "(?s)%s" $item.pattern) $text }}
      {{- $entries := list }}
      {{- range $bundle := $item.bundles }}
        {{- $entries = append $entries (dict "bundle" $bundle) }}
      {{- end }}
      {{- $matches = append $matches (dict "component" $item.component "entries" $entries "requires" $entries) }}
    {{- end }}
  {{- else }}
    {{- $component := $item.component | replace "." `\.` }}
    {{- $blocks := regexFindAll (printf `%s\s+"[^"]*"\s*\{%s\}` $component $nested) $text -1 }}
    {{- if gt (len (regexFindAll (printf `%s\s+"[^"]*"\s*\{` $component) $text -1)) (len $blocks) }}
      {{- fail (printf "\nCould not read a %s block to compute its RBAC for rbac.mode: minimal.\nPlease check that its braces are balanced, or set rbac.mode: alloy for this collector." $item.component) }}
    {{- end }}
    {{- range $block := $blocks }}
      {{- $inner := regexReplaceAll `^[^{]*\{` (trimSuffix "}" $block) "" }}
      {{- $body := $inner }}
      {{- range $_ := until 8 }}
        {{- $body = regexReplaceAll `\{[^{}]*\}` $body "{}" }}
      {{- end }}
      {{- if or (not $item.match) (regexMatch (printf "(?s)%s" ($item.match | default "")) $inner) }}
        {{- if $item.namedObject }}
          {{- $name := include "collectors.rbac.literal" (dict "value" (include "collectors.rbac.attribute" (dict "body" $body "name" "name"))) }}
          {{- $namespace := include "collectors.rbac.literal" (dict "value" (include "collectors.rbac.attribute" (dict "body" $body "name" "namespace"))) }}
          {{- $entry := dict "bundle" $item.namedObject "namespaces" (compact (list $namespace)) "resourceNames" (compact (list $name)) }}
          {{- $matches = append $matches (dict "component" $item.component "entries" (list $entry) "requires" (list $entry)) }}
        {{- else }}
          {{- $scope := include "collectors.rbac.scope" (dict "item" $item "block" $inner "body" $body "releaseNamespace" $.releaseNamespace) | fromYaml }}
          {{- $namespaces := $item.namespaces | default $scope.namespaces }}
          {{- $bundles := $item.bundles | default list }}
          {{- $unknown := $scope.unknown }}
          {{- if $item.roles }}
            {{- $roleValue := include "collectors.rbac.attribute" (dict "body" $body "name" "role") }}
            {{- $role := include "collectors.rbac.literal" (dict "value" $roleValue) }}
            {{- if $role }}
              {{- $bundles = get $item.roles $role | default list }}
            {{- else if $roleValue }}
              {{- $bundles = list }}
              {{- range $_, $roleBundles := $item.roles }}{{ $bundles = concat $bundles $roleBundles }}{{ end }}
              {{- $bundles = $bundles | uniq | sortAlpha }}
              {{- $unknown = true }}
            {{- end }}
          {{- end }}
          {{- $entries := list }}
          {{- $requires := list }}
          {{- range $bundle := $bundles }}
            {{- $entries = append $entries (dict "bundle" $bundle "namespaces" (ternary (list) $namespaces $unknown)) }}
            {{- if or (not $item.requires) (has $bundle $item.requires) }}
              {{- $requires = append $requires (dict "bundle" $bundle "namespaces" $namespaces) }}
            {{- end }}
          {{- end }}
          {{- range $bundle := $item.clusterBundles | default list }}
            {{- $entries = append $entries (dict "bundle" $bundle) }}
          {{- end }}
          {{- if $entries }}
            {{- $matches = append $matches (dict "component" $item.component "entries" $entries "requires" $requires "anyScope" $unknown) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $matches | toYaml }}
{{- end }}

{{/* Inputs: . (entries). Output: like "pods in a, b" */}}
{{- define "collectors.rbac.describe" -}}
{{- $descriptions := list }}
{{- range $entry := . }}
  {{- $description := $entry.bundle }}
  {{- with $entry.resourceNames }}{{ $description = printf "%s %s" $description (join ", " .) }}{{ end }}
  {{- with $entry.namespaces }}{{ $description = printf "%s in %s" $description (join ", " .) }}{{ end }}
  {{- $descriptions = append $descriptions $description }}
{{- end }}
{{- join ", " ($descriptions | uniq) }}
{{- end }}

{{/* Inputs: catalog, entries. Output: {cluster, namespaced}, mapping "apiGroup|resource|name" or a URL to verbs */}}
{{- define "collectors.rbac.expand" -}}
{{- $state := dict "cluster" (dict) "namespaced" (dict) }}
{{- range $entry := .entries }}
  {{- $bundle := get $.catalog $entry.bundle }}
  {{- if not $bundle }}
    {{- fail (printf "\nUnknown RBAC bundle %q." $entry.bundle) }}
  {{- end }}
  {{- range $rule := $bundle.rules }}
    {{- range $url := $rule.nonResourceURLs }}
      {{- $_ := set $state.cluster $url (concat (get $state.cluster $url | default list) $rule.verbs | uniq | sortAlpha) }}
    {{- end }}
    {{- range $resource := $rule.resources }}
      {{- $scopes := list "" }}
      {{- if and $entry.namespaces (not $rule.clusterScoped) }}
        {{- $scopes = $entry.namespaces }}
      {{- end }}
      {{- range $scope := $scopes }}
        {{- $rules := $state.cluster }}
        {{- if $scope }}
          {{- $rules = get $state.namespaced $scope | default dict }}
          {{- $_ := set $state.namespaced $scope $rules }}
        {{- end }}
        {{- range $apiGroup := $rule.apiGroups }}
          {{- range $name := $rule.resourceNames | default ($entry.resourceNames | default (list "")) }}
            {{- $key := printf "%s|%s|%s" $apiGroup $resource $name }}
            {{- $_ := set $rules $key (concat (get $rules $key | default list) $rule.verbs | uniq | sortAlpha) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $state | toYaml }}
{{- end }}

{{/* Inputs: rules, key, verbs, sameScope */}}
{{- define "collectors.rbac.coveredBy" -}}
{{- $parts := splitList "|" .key }}
{{- $candidates := list }}
{{- if not .sameScope }}
  {{- $candidates = append $candidates .key }}
{{- end }}
{{- if eq (len $parts) 3 }}
  {{- if index $parts 2 }}
    {{- $candidates = append $candidates (printf "%s|%s|" (index $parts 0) (index $parts 1)) }}
  {{- end }}
{{- end }}
{{- $covered := false }}
{{- range $candidate := $candidates }}
  {{- $granted := get ($.rules | default dict) $candidate | default (list) }}
  {{- if $granted }}
    {{- $missing := false }}
    {{- range $verb := $.verbs }}
      {{- if not (or (has "*" $granted) (has $verb $granted)) }}{{ $missing = true }}{{ end }}
    {{- end }}
    {{- if not $missing }}{{ $covered = true }}{{ end }}
  {{- end }}
{{- end }}
{{- $covered }}
{{- end }}

{{/* Inputs: catalog, grants (from expand), entry, anyScope (a grant in any namespace counts) */}}
{{- define "collectors.rbac.isCovered" -}}
{{- $required := include "collectors.rbac.expand" (dict "catalog" .catalog "entries" (list .entry)) | fromYaml }}
{{- $covered := true }}
{{- range $scope, $rules := merge (dict "" $required.cluster) $required.namespaced }}
  {{- range $key, $verbs := $rules }}
    {{- $candidates := list $.grants.cluster }}
    {{- if $scope }}{{ $candidates = append $candidates (get $.grants.namespaced $scope) }}{{ end }}
    {{- if $.anyScope }}{{ $candidates = concat $candidates (values $.grants.namespaced) }}{{ end }}
    {{- $found := false }}
    {{- range $rulesInScope := $candidates }}
      {{- if eq (include "collectors.rbac.coveredBy" (dict "rules" $rulesInScope "key" $key "verbs" $verbs "sameScope" false)) "true" }}{{ $found = true }}{{ end }}
    {{- end }}
    {{- if not $found }}{{ $covered = false }}{{ end }}
  {{- end }}
{{- end }}
{{- $covered }}
{{- end }}

{{/* Inputs: . (map of keys to verbs) */}}
{{- define "collectors.rbac.groupRules" -}}
{{- $groups := dict }}
{{- range $key, $verbs := . }}
  {{- $parts := splitList "|" $key }}
  {{- $groupKey := printf "3|%s" (join "," $verbs) }}
  {{- $item := $key }}
  {{- if not (hasPrefix "/" $key) }}
    {{- $groupKey = printf "1|%s|%s" (index $parts 0) (join "," $verbs) }}
    {{- $item = index $parts 1 }}
    {{- if index $parts 2 }}
      {{- $groupKey = printf "2|%s|%s|%s" (index $parts 0) (index $parts 1) (join "," $verbs) }}
      {{- $item = index $parts 2 }}
    {{- end }}
  {{- end }}
  {{- $group := get $groups $groupKey | default (dict "parts" $parts "verbs" $verbs "items" (list)) }}
  {{- $_ := set $group "items" (append $group.items $item) }}
  {{- $_ := set $groups $groupKey $group }}
{{- end }}
{{- $rules := list }}
{{- range $groupKey, $group := $groups }}
  {{- if hasPrefix "3|" $groupKey }}
    {{- $rules = append $rules (dict "nonResourceURLs" $group.items "verbs" $group.verbs) }}
  {{- else if hasPrefix "1|" $groupKey }}
    {{- $rules = append $rules (dict "apiGroups" (list (index $group.parts 0)) "resources" $group.items "verbs" $group.verbs) }}
  {{- else }}
    {{- $rules = append $rules (dict "apiGroups" (list (index $group.parts 0)) "resources" (list (index $group.parts 1)) "resourceNames" $group.items "verbs" $group.verbs) }}
  {{- end }}
{{- end }}
{{- $rules | toYaml }}
{{- end }}

{{/* Inputs: catalog, entries. Output: {cluster, namespaced} */}}
{{- define "collectors.rbac.resolve" -}}
{{- $state := include "collectors.rbac.expand" (dict "catalog" .catalog "entries" .entries) | fromYaml }}
{{- $cluster := dict }}
{{- range $key, $verbs := $state.cluster }}
  {{- if ne (include "collectors.rbac.coveredBy" (dict "rules" $state.cluster "key" $key "verbs" $verbs "sameScope" true)) "true" }}
    {{- $_ := set $cluster $key $verbs }}
  {{- end }}
{{- end }}
{{- $namespaced := dict }}
{{- range $namespace, $rules := $state.namespaced }}
  {{- $kept := dict }}
  {{- range $key, $verbs := $rules }}
    {{- $coveredByCluster := include "collectors.rbac.coveredBy" (dict "rules" $state.cluster "key" $key "verbs" $verbs "sameScope" false) }}
    {{- $coveredByNamespace := include "collectors.rbac.coveredBy" (dict "rules" $rules "key" $key "verbs" $verbs "sameScope" true) }}
    {{- if and (ne $coveredByCluster "true") (ne $coveredByNamespace "true") }}
      {{- $_ := set $kept $key $verbs }}
    {{- end }}
  {{- end }}
  {{- if $kept }}
    {{- $_ := set $namespaced $namespace (include "collectors.rbac.groupRules" $kept | fromYamlArray) }}
  {{- end }}
{{- end }}
{{- dict "cluster" (include "collectors.rbac.groupRules" $cluster | fromYamlArray) "namespaced" $namespaced | toYaml }}
{{- end }}

{{/* Inputs: annotations (map of lists) */}}
{{- define "collectors.rbac.annotations" -}}
{{- $annotations := dict }}
{{- range $name, $values := .annotations }}
  {{- if $values }}{{ $_ := set $annotations (printf "k8s.grafana.com/%s" $name) (join "; " $values) }}{{ end }}
{{- end }}
{{- with $annotations }}
annotations:
  {{- range $name, $value := . }}
  {{ $name }}: {{ $value | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Inputs: name (instance fullname), namespace, labels, serviceAccountName, resolved, annotations */}}
{{- define "collectors.rbac.render" }}
{{- $subjects := list (dict "kind" "ServiceAccount" "name" .serviceAccountName "namespace" .namespace) }}
{{- $annotations := include "collectors.rbac.annotations" . | trim }}
{{- $clusterName := printf "%s-rbac" .name }}
{{- if .resolved.cluster }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ $clusterName }}
  labels:
    {{- toYaml .labels | nindent 4 }}
  {{- with $annotations }}{{ . | nindent 2 }}{{ end }}
rules:
  {{- toYaml .resolved.cluster | nindent 2 }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ $clusterName }}
  labels:
    {{- toYaml .labels | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ $clusterName }}
subjects:
  {{- toYaml $subjects | nindent 2 }}
{{- end }}
{{- range $namespace, $rules := .resolved.namespaced }}
{{- $name := $clusterName }}
{{- /* Releases with the same name in different namespaces can share a Secret namespace. */}}
{{- if ne $namespace $.namespace }}{{ $name = printf "%s-%s-rbac" $.name $.namespace }}{{ end }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $name }}
  namespace: {{ $namespace }}
  labels:
    {{- toYaml $.labels | nindent 4 }}
  {{- with $annotations }}{{ . | nindent 2 }}{{ end }}
rules:
  {{- toYaml $rules | nindent 2 }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ $name }}
  namespace: {{ $namespace }}
  labels:
    {{- toYaml $.labels | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ $name }}
subjects:
  {{- toYaml $subjects | nindent 2 }}
{{- end }}
{{- end }}

{{/* Inputs: Files, entries, userConfig, config (final config), releaseNamespace. Output: {resolved, inferred, userConfig} */}}
{{- define "collectors.rbac.compute" -}}
{{- $catalog := .Files.Get "collectors/rbac-bundles.yaml" | fromYaml }}
{{- $components := .Files.Get "collectors/alloy-kubernetes-api.yaml" | fromYamlArray }}
{{- $entries := .entries }}
{{- $userConfig := list }}
{{- range $user := .userConfig }}
  {{- range $match := include "collectors.rbac.scan" (dict "components" $components "text" $user.text "releaseNamespace" $.releaseNamespace) | fromYamlArray }}
    {{- $entries = concat $entries $match.entries }}
    {{- $userConfig = append $userConfig (printf "%s from %s (%s)" $match.component $user.source (include "collectors.rbac.describe" $match.entries)) }}
  {{- end }}
{{- end }}
{{- $inferred := list }}
{{- $grants := include "collectors.rbac.expand" (dict "catalog" $catalog "entries" $entries) | fromYaml }}
{{- range $match := include "collectors.rbac.scan" (dict "components" $components "text" .config "releaseNamespace" .releaseNamespace) | fromYamlArray }}
  {{- $covered := true }}
  {{- range $required := $match.requires }}
    {{- if ne (include "collectors.rbac.isCovered" (dict "catalog" $catalog "grants" $grants "entry" $required "anyScope" $match.anyScope)) "true" }}
      {{- $covered = false }}
    {{- end }}
  {{- end }}
  {{- if not $covered }}
    {{- $entries = concat $entries $match.entries }}
    {{- $inferred = append $inferred (printf "%s (%s)" $match.component (include "collectors.rbac.describe" $match.entries)) }}
  {{- end }}
{{- end }}
{{- $resolved := include "collectors.rbac.resolve" (dict "catalog" $catalog "entries" $entries) | fromYaml }}
{{- dict "resolved" $resolved "inferred" ($inferred | uniq | sortAlpha) "userConfig" ($userConfig | uniq) | toYaml }}
{{- end }}

{{/* Inputs: root, values (root-like with collectorName), alloyValues (the collector.alloy.values result), entries, userConfig, config (final config) */}}
{{- define "collectors.rbac.instance" }}
{{- if dig "rbac" "create" true .alloyValues }}
  {{- $name := include "collector.alloy.fullname" .values }}
  {{- $namespace := include "helper.namespace" .root }}
  {{- $serviceAccountName := include "collector.alloy.serviceAccountName" (merge (dict "alloyValues" .alloyValues) .values) }}
  {{- $computed := include "collectors.rbac.compute" (dict "Files" .root.Files "entries" .entries "userConfig" .userConfig "config" .config "releaseNamespace" $namespace) | fromYaml }}
  {{- $labels := merge (dict "app.kubernetes.io/component" "rbac" "app.kubernetes.io/instance" $name) (include "collector.alloy.labels" .root | fromYaml) }}
  {{- $annotations := dict "rbac-inferred" $computed.inferred "rbac-user-config" $computed.userConfig }}
  {{- include "collectors.rbac.render" (dict "name" $name "namespace" $namespace "labels" $labels "serviceAccountName" $serviceAccountName "resolved" $computed.resolved "annotations" $annotations) }}
{{- end }}
{{- end }}
