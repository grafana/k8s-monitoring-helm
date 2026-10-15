{{/* The one rule minimal mode takes from values, because it isn't in the config: the SDK Injector only accepts ConfigMaps from the users in allowedConfigMapWriters, so a collector whose ServiceAccount is listed there can write ConfigMaps in the release namespace. Inputs: . (root with collectorName). Output: [{bundle, namespaces}] */}}
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

{{/* Expands entries into grants: every rule of an entry's bundle becomes "apiGroup|resource|name" keys with verbs, in each of the entry's namespaces, or cluster-wide when it has none. clusterScoped rules and nonResourceURLs are always cluster-wide. Inputs: catalog, entries. Output: {cluster, namespaced}, mapping "apiGroup|resource|name" or a URL to verbs */}}
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

{{/* Whether rules already grant all of a key's verbs, for the key itself or, when the key names an object, for every object of that resource. With sameScope, the key itself doesn't count, so a grant doesn't cover itself. Inputs: rules, key, verbs, sameScope. Output: "true" or "false" */}}
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

{{/* Turns grants into RBAC rules in a stable order: resources with the same API group and verbs share a rule, named objects share a rule per resource, and URLs share a rule per verbs. Inputs: . (map of keys to verbs). Output: [rules] */}}
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

{{/* Computes an instance's rules from its entries: expands them, drops grants that the ClusterRole or a broader grant in the same namespace already covers, and groups the rest into ClusterRole rules and rules for each namespace's Role. Inputs: catalog, entries. Output: {cluster, namespaced} */}}
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

{{/* Renders the ClusterRole, a Role per namespace, and their bindings to the instance's ServiceAccount, skipping the ClusterRole when it has no rules. The ClusterRole and Roles outside the release namespace include the release namespace in their names, so releases with the same name in different namespaces don't collide. Inputs: name (instance fullname), namespace, labels, serviceAccountName, resolved */}}
{{- define "collectors.rbac.render" }}
{{- $subjects := list (dict "kind" "ServiceAccount" "name" .serviceAccountName "namespace" .namespace) }}
{{- $qualifiedName := printf "%s-%s-rbac" .name .namespace }}
{{- if .resolved.cluster }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ $qualifiedName }}
  labels:
    {{- toYaml .labels | nindent 4 }}
rules:
  {{- toYaml .resolved.cluster | nindent 2 }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ $qualifiedName }}
  labels:
    {{- toYaml .labels | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ $qualifiedName }}
subjects:
  {{- toYaml $subjects | nindent 2 }}
{{- end }}
{{- range $namespace, $rules := .resolved.namespaced }}
{{- $name := ternary (printf "%s-rbac" $.name) $qualifiedName (eq $namespace $.namespace) }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $name }}
  namespace: {{ $namespace }}
  labels:
    {{- toYaml $.labels | nindent 4 }}
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

{{/* Computes an instance's resolved rules from the bundle catalog and its entries. Inputs: Files, entries (rules from values). Output: {cluster, namespaced} */}}
{{- define "collectors.rbac.compute" -}}
{{- $catalog := .Files.Get "collectors/rbac-bundles.yaml" | fromYaml }}
{{- include "collectors.rbac.resolve" (dict "catalog" $catalog "entries" (.entries | default list)) }}
{{- end }}

{{/* Renders the RBAC objects of one collector, sampler, or service graph instance in minimal mode, unless its rbac.create is false. Inputs: root, values (root-like with collectorName), alloyValues (the collector.alloy.values result), entries (optional, rules from values) */}}
{{- define "collectors.rbac.instance" }}
{{- if dig "rbac" "create" true .alloyValues }}
  {{- $name := include "collector.alloy.fullname" .values }}
  {{- $namespace := include "helper.namespace" .root }}
  {{- $serviceAccountName := include "collector.alloy.serviceAccountName" (merge (dict "alloyValues" .alloyValues) .values) }}
  {{- $resolved := include "collectors.rbac.compute" (dict "Files" .root.Files "entries" .entries) | fromYaml }}
  {{- $labels := merge (dict "app.kubernetes.io/component" "rbac" "app.kubernetes.io/instance" $name) (include "collector.alloy.labels" .root | fromYaml) }}
  {{- include "collectors.rbac.render" (dict "name" $name "namespace" $namespace "labels" $labels "serviceAccountName" $serviceAccountName "resolved" $resolved) }}
{{- end }}
{{- end }}
