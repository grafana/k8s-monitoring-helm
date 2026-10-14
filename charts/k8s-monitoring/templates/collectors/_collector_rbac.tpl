{{/* RBAC for Alloy instances with `rbac.mode: minimal`. See docs/RBAC.md. */}}

{{/* Inputs: . (root with collectorName), featureKeys, destinationNames */}}
{{- define "collectors.rbac.entries" -}}
{{- $entries := list }}
{{- range $featureKey := .featureKeys }}
  {{- $entries = concat $entries (include (printf "features.%s.rbac" $featureKey) $ | fromYamlArray) }}
{{- end }}
{{- $entries = concat $entries (include "collectors.rbac.destinationEntries" $ | fromYamlArray) }}
{{- $entries = concat $entries (include "collectors.rbac.sdkInjectorEntries" $ | fromYamlArray) }}
{{- $entries | toYaml }}
{{- end }}

{{/* Inputs: . (root), destination (with defaults), destinationName */}}
{{- define "collectors.rbac.secretEntry" -}}
{{- $secretArgs := dict "Values" .Values "Chart" .Chart "Release" .Release "object" .destination "name" .destinationName }}
{{- dict "bundle" "secret" "namespaces" (list (include "secrets.kubernetesSecretNamespace" $secretArgs)) "resourceNames" (list (include "secrets.kubernetesSecretName" $secretArgs)) | toYaml }}
{{- end }}

{{/* Inputs: . (root with collectorName), destinationNames */}}
{{- define "collectors.rbac.destinationEntries" -}}
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

{{/* The value of a top-level attribute in a component body, or "" if it isn't set. Inputs: body, name */}}
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

{{/* The namespaces a component block is limited to. Inputs: item, block, body (block without nested blocks), releaseNamespace. Output: {namespaces, unknown} */}}
{{- define "collectors.rbac.scope" -}}
{{- $namespaces := list }}
{{- $unknown := eq (.item.scope | default "") "unknown" }}
{{- $list := "" }}
{{- if eq .item.scope "namespacesBlock" }}
  {{- $nested := regexFind `namespaces\s*\{[^{}]*\}` .block }}
  {{- if regexMatch `own_namespace\s*=\s*true` $nested }}
    {{- $namespaces = list .releaseNamespace }}
  {{- else if $nested }}
    {{- $list = include "collectors.rbac.attribute" (dict "body" (trimSuffix "}" (regexReplaceAll `^namespaces\s*\{` $nested "")) "name" "names") }}
    {{- if not $list }}{{ $unknown = true }}{{ end }}
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
{{- dict "namespaces" $namespaces "unknown" $unknown | toYaml }}
{{- end }}

{{/* Finds the components in collectors/alloy-kubernetes-api.yaml in configuration text. Inputs: components, text, releaseNamespace. Output: [{component, entries, requires, anyScope}] */}}
{{- define "collectors.rbac.scan" -}}
{{- $matches := list }}
{{- $nested := `[^{}]*` }}
{{- range $_ := until 8 }}
  {{- $nested = printf `(?:[^{}]|\{%s\})*` $nested }}
{{- end }}
{{- range $item := .components }}
  {{- if $item.pattern }}
    {{- if regexMatch (printf "(?s)%s" $item.pattern) $.text }}
      {{- $entries := list }}
      {{- range $bundle := $item.bundles }}
        {{- $entries = append $entries (dict "bundle" $bundle) }}
      {{- end }}
      {{- $matches = append $matches (dict "component" $item.component "entries" $entries "requires" $entries) }}
    {{- end }}
  {{- else }}
    {{- range $block := regexFindAll (printf `%s\s+"[^"]*"\s*\{%s\}` ($item.component | replace "." `\.`) $nested) $.text -1 }}
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
          {{- if $item.roles }}
            {{- $role := include "collectors.rbac.literal" (dict "value" (include "collectors.rbac.attribute" (dict "body" $body "name" "role"))) }}
            {{- $bundles = get $item.roles $role | default list }}
          {{- end }}
          {{- $entries := list }}
          {{- $requires := list }}
          {{- range $bundle := $bundles }}
            {{- $entries = append $entries (dict "bundle" $bundle "namespaces" (ternary (list) $namespaces $scope.unknown)) }}
            {{- if or (not $item.requires) (has $bundle $item.requires) }}
              {{- $requires = append $requires (dict "bundle" $bundle "namespaces" $namespaces) }}
            {{- end }}
          {{- end }}
          {{- range $bundle := $item.clusterBundles | default list }}
            {{- $entries = append $entries (dict "bundle" $bundle) }}
          {{- end }}
          {{- if $entries }}
            {{- $matches = append $matches (dict "component" $item.component "entries" $entries "requires" $requires "anyScope" $scope.unknown) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $matches | toYaml }}
{{- end }}

{{/* Describes entries for annotations, like "pods in a, b". Inputs: . (entries) */}}
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

{{/* Adds verbs for one resource to a scope. Inputs: state, scope ("" for the ClusterRole), key, verbs */}}
{{- define "collectors.rbac.addRule" -}}
{{- $rules := .state.cluster }}
{{- if .scope }}
  {{- $rules = get .state.namespaced .scope | default (dict) }}
  {{- $_ := set .state.namespaced .scope $rules }}
{{- end }}
{{- $_ := set $rules .key (concat (get $rules .key | default (list)) .verbs | uniq | sortAlpha) }}
{{- end }}

{{/* Inputs: state, scopes, rule (PolicyRule) */}}
{{- define "collectors.rbac.addPolicyRule" -}}
{{- range $url := .rule.nonResourceURLs | default (list) }}
  {{- $_ := include "collectors.rbac.addRule" (dict "state" $.state "scope" "" "key" (printf "u|%s" $url) "verbs" $.rule.verbs) }}
{{- end }}
{{- range $apiGroup := .rule.apiGroups | default (list) }}
  {{- range $resource := $.rule.resources | default (list) }}
    {{- range $scope := $.scopes }}
      {{- range $name := $.rule.resourceNames | default (list "") }}
        {{- $_ := include "collectors.rbac.addRule" (dict "state" $.state "scope" $scope "key" (printf "r|%s|%s|%s" $apiGroup $resource $name) "verbs" $.rule.verbs) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Expands entries into rules per scope. Inputs: catalog, entries, restrictTo (rbac.namespaces). Output: {cluster, namespaced, dropped} */}}
{{- define "collectors.rbac.expand" -}}
{{- $clusterScopedResources := list "nodes" "nodes/metrics" "nodes/pods" "nodes/proxy" "namespaces" "infrastructures" "infrastructures/status" }}
{{- $restrictTo := .restrictTo | default (list) }}
{{- $state := dict "cluster" (dict) "namespaced" (dict) }}
{{- $dropped := list }}
{{- range $entry := .entries }}
  {{- $bundle := get $.catalog $entry.bundle }}
  {{- if not $bundle }}
    {{- fail (printf "\nUnknown RBAC bundle %q." $entry.bundle) }}
  {{- end }}
  {{- range $rule := $bundle.rules }}
    {{- $names := $rule.resourceNames | default ($entry.resourceNames | default (list "")) }}
    {{- if $rule.nonResourceURLs }}
      {{- if $restrictTo }}
        {{- $dropped = append $dropped $entry.bundle }}
      {{- else }}
        {{- $_ := include "collectors.rbac.addPolicyRule" (dict "state" $state "scopes" (list "") "rule" $rule) }}
      {{- end }}
    {{- end }}
    {{- range $resource := $rule.resources | default (list) }}
      {{- $scopes := list "" }}
      {{- if or $bundle.clusterOnly (has $resource $clusterScopedResources) }}
        {{- if $restrictTo }}
          {{- $scopes = list }}
          {{- $dropped = append $dropped $entry.bundle }}
        {{- end }}
      {{- else if $entry.namespaces }}
        {{- $scopes = $entry.namespaces }}
      {{- else if $restrictTo }}
        {{- $scopes = $restrictTo }}
      {{- end }}
      {{- $_ := include "collectors.rbac.addPolicyRule" (dict "state" $state "scopes" $scopes "rule" (dict "apiGroups" $rule.apiGroups "resources" (list $resource) "resourceNames" (compact $names) "verbs" $rule.verbs)) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $_ := set $state "dropped" $dropped }}
{{- $state | toYaml }}
{{- end }}

{{/* Returns "true" if rules already grant the verbs for a key. Inputs: rules, key, verbs, sameScope */}}
{{- define "collectors.rbac.coveredBy" -}}
{{- $parts := splitList "|" .key }}
{{- $candidates := list }}
{{- if not .sameScope }}
  {{- $candidates = append $candidates .key }}
{{- end }}
{{- if and (eq (first $parts) "r") (last $parts) }}
  {{- $candidates = append $candidates (printf "r|%s|%s|" (index $parts 1) (index $parts 2)) }}
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

{{/* Returns "true" if the grants cover an entry in its scope, or in any scope with anyScope. Inputs: catalog, grants (from expand), entry, anyScope */}}
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

{{/* Groups a map of keys to verbs into PolicyRules. Inputs: . (map) */}}
{{- define "collectors.rbac.groupRules" -}}
{{- $groups := dict }}
{{- range $key, $verbs := . }}
  {{- $parts := splitList "|" $key }}
  {{- $groupKey := "" }}
  {{- $item := "" }}
  {{- if eq (first $parts) "u" }}
    {{- $groupKey = printf "3|%s" (join "," $verbs) }}
    {{- $item = index $parts 1 }}
  {{- else if eq (index $parts 3) "" }}
    {{- $groupKey = printf "1|%s|%s" (index $parts 1) (join "," $verbs) }}
    {{- $item = index $parts 2 }}
  {{- else }}
    {{- $groupKey = printf "2|%s|%s|%s" (index $parts 1) (index $parts 2) (join "," $verbs) }}
    {{- $item = index $parts 3 }}
  {{- end }}
  {{- $group := get $groups $groupKey | default (dict "parts" $parts "verbs" $verbs "items" (list)) }}
  {{- $_ := set $group "items" (append $group.items $item) }}
  {{- $_ := set $groups $groupKey $group }}
{{- end }}
{{- $rules := list }}
{{- range $groupKey, $group := $groups }}
  {{- $kind := substr 0 1 $groupKey }}
  {{- if eq $kind "3" }}
    {{- $rules = append $rules (dict "nonResourceURLs" $group.items "verbs" $group.verbs) }}
  {{- else if eq $kind "1" }}
    {{- $rules = append $rules (dict "apiGroups" (list (index $group.parts 1)) "resources" $group.items "verbs" $group.verbs) }}
  {{- else }}
    {{- $rules = append $rules (dict "apiGroups" (list (index $group.parts 1)) "resources" (list (index $group.parts 2)) "resourceNames" $group.items "verbs" $group.verbs) }}
  {{- end }}
{{- end }}
{{- $rules | toYaml }}
{{- end }}

{{/* Inputs: catalog, entries, rules (rbac.rules), clusterRules (rbac.clusterRules), namespaces (rbac.namespaces). Output: {cluster, namespaced, dropped} */}}
{{- define "collectors.rbac.resolve" -}}
{{- $restrictTo := .namespaces | default (list) }}
{{- $state := include "collectors.rbac.expand" (dict "catalog" .catalog "entries" .entries "restrictTo" $restrictTo) | fromYaml }}
{{- $dropped := $state.dropped | default list }}
{{- range $rule := .rules | default (list) }}
  {{- $_ := include "collectors.rbac.addPolicyRule" (dict "state" $state "scopes" ($restrictTo | default (list "")) "rule" (omit $rule "nonResourceURLs")) }}
  {{- if $rule.nonResourceURLs }}
    {{- if $restrictTo }}
      {{- $dropped = append $dropped "rbac.rules" }}
    {{- else }}
      {{- $_ := include "collectors.rbac.addPolicyRule" (dict "state" $state "scopes" (list "") "rule" (pick $rule "nonResourceURLs" "verbs")) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and .clusterRules $restrictTo }}
  {{- $dropped = append $dropped "rbac.clusterRules" }}
{{- else }}
  {{- range $rule := .clusterRules | default (list) }}
    {{- $_ := include "collectors.rbac.addPolicyRule" (dict "state" $state "scopes" (list "") "rule" $rule) }}
  {{- end }}
{{- end }}

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
{{- if and $dropped (not $cluster) (not $namespaced) }}
  {{- $_ := set $namespaced (first $restrictTo) (list) }}
{{- end }}
{{- dict "cluster" (include "collectors.rbac.groupRules" $cluster | fromYamlArray) "namespaced" $namespaced "dropped" ($dropped | uniq | sortAlpha) | toYaml }}
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

{{/* Inputs: name, namespace, labels, serviceAccountName, resolved, annotations */}}
{{- define "collectors.rbac.render" }}
{{- $subjects := list (dict "kind" "ServiceAccount" "name" .serviceAccountName "namespace" .namespace) }}
{{- $annotations := include "collectors.rbac.annotations" . | trim }}
{{- if .resolved.cluster }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ .name }}
  labels:
    {{- toYaml .labels | nindent 4 }}
  {{- with $annotations }}{{ . | nindent 2 }}{{ end }}
rules:
  {{- toYaml .resolved.cluster | nindent 2 }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ .name }}
  labels:
    {{- toYaml .labels | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ .name }}
subjects:
  {{- toYaml $subjects | nindent 2 }}
{{- end }}
{{- range $namespace, $rules := .resolved.namespaced }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $.name }}
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
  name: {{ $.name }}
  namespace: {{ $namespace }}
  labels:
    {{- toYaml $.labels | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ $.name }}
subjects:
  {{- toYaml $subjects | nindent 2 }}
{{- end }}
{{- end }}

{{/* Inputs: Files, collectorValues, entries, userConfig, config (final config), releaseNamespace. Output: {resolved, inferred, userConfig} */}}
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
{{- $rbac := .collectorValues.rbac | default dict }}
{{- $resolved := include "collectors.rbac.resolve" (dict "catalog" $catalog "entries" $entries "rules" $rbac.rules "clusterRules" $rbac.clusterRules "namespaces" $rbac.namespaces) | fromYaml }}
{{- dict "resolved" $resolved "inferred" ($inferred | uniq | sortAlpha) "userConfig" ($userConfig | uniq) | toYaml }}
{{- end }}

{{/* Inputs: Files, collectorValues, entries, userConfig, config, name (instance fullname), namespace, labels, serviceAccountName */}}
{{- define "collectors.rbac.instance" }}
{{- if dig "rbac" "create" true .collectorValues }}
  {{- $computed := include "collectors.rbac.compute" (merge (dict "releaseNamespace" .namespace) .) | fromYaml }}
  {{- $labels := merge (dict "app.kubernetes.io/component" "rbac" "app.kubernetes.io/instance" .name) .labels }}
  {{- $annotations := dict "rbac-inferred" $computed.inferred "rbac-user-config" $computed.userConfig "rbac-dropped" $computed.resolved.dropped }}
  {{- include "collectors.rbac.render" (dict "name" (printf "%s-rbac" .name) "namespace" .namespace "labels" $labels "serviceAccountName" .serviceAccountName "resolved" $computed.resolved "annotations" $annotations) }}
{{- end }}
{{- end }}
