{{/* RBAC for Alloy instances with `rbac.mode: minimal`. See docs/RBAC.md. */}}

{{/* Returns "true" if any value in the map is true. Inputs: . (map) */}}
{{- define "collectors.rbac.anyEnabled" -}}
{{- $found := false -}}
{{- range $_, $value := (. | default dict) -}}
  {{- if and (kindIs "bool" $value) $value }}{{ $found = true }}{{ end -}}
{{- end -}}
{{- $found -}}
{{- end }}

{{/* The RBAC entries computed for a collector from its features, destinations, and the SDK Injector.
     Inputs: . (root with collectorName), featureKeys, destinationNames */}}
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

{{/* The data processors used by the enabled features on a collector. Inputs: . (root), featureKeys */}}
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

{{/* Configuration text that users supply, which may contain any component. replacements are the full replaced components.
     Inputs: . (root), collectorValues, extraConfig (rendered), replacements (matched content), destinationNames, featureKeys */}}
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
    {{- range $_, $ecosystems := omit $processor "type" }}
      {{- if kindIs "map" $ecosystems }}
        {{- range $_, $settings := $ecosystems }}
          {{- if and (kindIs "map" $settings) $settings.config }}
            {{- $texts = append $texts (dict "source" (printf "data processor %s" $name) "text" $settings.config) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $texts | toYaml }}
{{- end }}

{{/* Finds the components in collectors/alloy-kubernetes-api.yaml that appear in configuration text.
     Inputs: Files, text. Output: a list of {component, entries, requires} */}}
{{- define "collectors.rbac.scan" -}}
{{- $matches := list }}
{{- range $item := .Files.Get "collectors/alloy-kubernetes-api.yaml" | fromYamlArray }}
  {{- $pattern := printf "(?s)%s" $item.pattern }}
  {{- if $item.namedObject }}
    {{- range $block := regexFindAll $pattern $.text -1 }}
      {{- $entry := dict "bundle" $item.namedObject }}
      {{- if and (regexMatch `\bname\s*=\s*"[^"]+"` $block) (regexMatch `\bnamespace\s*=\s*"[^"]+"` $block) }}
        {{- $name := regexReplaceAll `(?s)^.*?\bname\s*=\s*"([^"]+)".*$` $block "${1}" }}
        {{- $namespace := regexReplaceAll `(?s)^.*?\bnamespace\s*=\s*"([^"]+)".*$` $block "${1}" }}
        {{- $entry = dict "bundle" $item.namedObject "namespaces" (list $namespace) "resourceNames" (list $name) }}
      {{- end }}
      {{- $matches = append $matches (dict "component" $item.component "entries" (list $entry) "requires" (list $entry)) }}
    {{- end }}
  {{- else if regexMatch $pattern $.text }}
    {{- $entries := list }}
    {{- range $bundle := $item.bundles }}
      {{- $entries = append $entries (dict "bundle" $bundle "namespaces" ($item.namespaces | default list)) }}
    {{- end }}
    {{- $requires := list }}
    {{- range $bundle := $item.requires | default $item.bundles }}
      {{- $requires = append $requires (dict "bundle" $bundle) }}
    {{- end }}
    {{- $matches = append $matches (dict "component" $item.component "entries" $entries "requires" $requires) }}
  {{- end }}
{{- end }}
{{- $matches | toYaml }}
{{- end }}

{{/* Every resource and verb that entries grant, in any scope. Inputs: Files, entries. Output: a map of keys to verbs */}}
{{- define "collectors.rbac.grants" -}}
{{- $catalog := .Files.Get "collectors/rbac-bundles.yaml" | fromYaml }}
{{- $state := dict "cluster" (dict) "namespaced" (dict) }}
{{- range $entry := .entries }}
  {{- range $rule := (get $catalog $entry.bundle).rules }}
    {{- $rule = merge (dict "resourceNames" ($rule.resourceNames | default $entry.resourceNames)) $rule }}
    {{- $_ := include "collectors.rbac.addPolicyRule" (dict "state" $state "scopes" (list "") "rule" $rule) }}
  {{- end }}
{{- end }}
{{- $state.cluster | toYaml }}
{{- end }}

{{/* Returns "true" if the grants cover every rule of the entry. Inputs: Files, grants, entry */}}
{{- define "collectors.rbac.isCovered" -}}
{{- $covered := true }}
{{- range $key, $verbs := include "collectors.rbac.grants" (dict "Files" .Files "entries" (list .entry)) | fromYaml }}
  {{- if ne (include "collectors.rbac.coveredBy" (dict "rules" $.grants "key" $key "verbs" $verbs "sameScope" false)) "true" }}
    {{- $covered = false }}
  {{- end }}
{{- end }}
{{- $covered }}
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

{{/* Adds a user-supplied PolicyRule. Inputs: state, scopes, rule */}}
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
  {{- $granted := get $.rules $candidate | default (list) }}
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

{{/* Turns RBAC entries and user rules into the rules for a ClusterRole and per-namespace Roles.
     Inputs: Files, entries, rules (rbac.rules), clusterRules (rbac.clusterRules), namespaces (rbac.namespaces)
     Output: {cluster: [rules], namespaced: {namespace: [rules]}, dropped: [bundle names]} */}}
{{- define "collectors.rbac.resolve" -}}
{{- $catalog := .Files.Get "collectors/rbac-bundles.yaml" | fromYaml }}
{{- $clusterScopedResources := list "nodes" "nodes/metrics" "nodes/pods" "nodes/proxy" "namespaces" "infrastructures" "infrastructures/status" }}
{{- $restrictTo := .namespaces | default (list) }}
{{- $state := dict "cluster" (dict) "namespaced" (dict) }}
{{- $dropped := list }}
{{- range $entry := .entries }}
  {{- $bundle := get $catalog $entry.bundle }}
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
{{- dict "cluster" (include "collectors.rbac.groupRules" $cluster | fromYamlArray) "namespaced" $namespaced "dropped" ($dropped | uniq | sortAlpha) | toYaml }}
{{- end }}

{{/* Inputs: name, namespace, labels, serviceAccountName, resolved, inferred */}}
{{- define "collectors.rbac.render" }}
{{- $subjects := list (dict "kind" "ServiceAccount" "name" .serviceAccountName "namespace" .namespace) }}
{{- if .resolved.cluster }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ .name }}
  labels:
    {{- toYaml .labels | nindent 4 }}
  {{- with .inferred }}
  annotations:
    k8s.grafana.com/rbac-inferred: {{ join "; " . | quote }}
  {{- end }}
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
  {{- with $.inferred }}
  annotations:
    k8s.grafana.com/rbac-inferred: {{ join "; " . | quote }}
  {{- end }}
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

{{/* The RBAC computation for one Alloy instance, before rendering.
     Inputs: Files, collectorValues, entries (computed), userConfig (from collectors.rbac.userConfig), config (final config, or empty to skip the drift guard)
     Output: {resolved, inferred, userComponents} */}}
{{- define "collectors.rbac.compute" -}}
{{- $entries := .entries }}
{{- $userComponents := list }}
{{- range $user := .userConfig }}
  {{- range $match := include "collectors.rbac.scan" (dict "Files" $.Files "text" $user.text) | fromYamlArray }}
    {{- $entries = concat $entries $match.entries }}
    {{- $userComponents = append $userComponents (printf "%s (%s)" $match.component $user.source) }}
  {{- end }}
{{- end }}
{{- $inferred := list }}
{{- if .config }}
  {{- $grants := include "collectors.rbac.grants" (dict "Files" $.Files "entries" $entries) | fromYaml }}
  {{- range $match := include "collectors.rbac.scan" (dict "Files" $.Files "text" $.config) | fromYamlArray }}
    {{- $covered := true }}
    {{- range $required := $match.requires }}
      {{- if ne (include "collectors.rbac.isCovered" (dict "Files" $.Files "grants" $grants "entry" $required)) "true" }}
        {{- $covered = false }}
      {{- end }}
    {{- end }}
    {{- if not $covered }}
      {{- $entries = concat $entries $match.entries }}
      {{- $bundles := list }}
      {{- range $entry := $match.entries }}
        {{- $bundles = append $bundles (printf "%s%s" $entry.bundle (ternary (printf " %s/%s" (first ($entry.namespaces | default (list ""))) (first ($entry.resourceNames | default (list "")))) "" (not (empty $entry.resourceNames)))) }}
      {{- end }}
      {{- $inferred = append $inferred (printf "%s (%s)" $match.component (join ", " $bundles)) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $rbac := .collectorValues.rbac | default dict }}
{{- $resolved := include "collectors.rbac.resolve" (dict "Files" .Files "entries" $entries "rules" $rbac.rules "clusterRules" $rbac.clusterRules "namespaces" $rbac.namespaces) | fromYaml }}
{{- dict "resolved" $resolved "inferred" ($inferred | uniq | sortAlpha) "userComponents" ($userComponents | uniq) | toYaml }}
{{- end }}

{{/* Renders the RBAC for one Alloy instance in minimal mode.
     Inputs: Files, collectorValues, entries, userConfig, config, name (instance fullname), namespace, labels, serviceAccountName, valuesPath */}}
{{- define "collectors.rbac.instance" }}
{{- include "collectors.validate.rbac" (dict "name" .name "collectorValues" .collectorValues "valuesPath" .valuesPath) }}
{{- if dig "rbac" "create" true .collectorValues }}
  {{- $computed := include "collectors.rbac.compute" . | fromYaml }}
  {{- $labels := merge (dict "app.kubernetes.io/component" "rbac" "app.kubernetes.io/instance" .name) .labels }}
  {{- include "collectors.rbac.render" (dict "name" (printf "%s-rbac" .name) "namespace" .namespace "labels" $labels "serviceAccountName" .serviceAccountName "resolved" $computed.resolved "inferred" $computed.inferred) }}
{{- end }}
{{- end }}
