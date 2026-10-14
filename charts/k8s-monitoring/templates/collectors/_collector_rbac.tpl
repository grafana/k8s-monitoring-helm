{{/* RBAC for Alloy instances with `rbac.mode: minimal`. See docs/RBAC.md. */}}

{{/* Inputs: . (root with collectorName), destinationNames */}}
{{- define "collectors.rbac.entries" -}}
{{- $entries := include "collectors.rbac.destinationEntries" $ | fromYamlArray }}
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

{{/* Expands entries into rules per namespace. Inputs: catalog, entries. Output: {namespace: {"apiGroup|resource|name": verbs}} */}}
{{- define "collectors.rbac.expand" -}}
{{- $namespaced := dict }}
{{- range $entry := .entries }}
  {{- $bundle := get $.catalog $entry.bundle }}
  {{- if not $bundle }}
    {{- fail (printf "\nUnknown RBAC bundle %q." $entry.bundle) }}
  {{- end }}
  {{- range $namespace := $entry.namespaces }}
    {{- $rules := get $namespaced $namespace | default dict }}
    {{- range $rule := $bundle.rules }}
      {{- range $apiGroup := $rule.apiGroups }}
        {{- range $resource := $rule.resources }}
          {{- range $name := $entry.resourceNames | default (list "") }}
            {{- $key := printf "%s|%s|%s" $apiGroup $resource $name }}
            {{- $_ := set $rules $key (concat (get $rules $key | default list) $rule.verbs | uniq | sortAlpha) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- $_ := set $namespaced $namespace $rules }}
  {{- end }}
{{- end }}
{{- $namespaced | toYaml }}
{{- end }}

{{/* Groups a map of keys to verbs into PolicyRules. Inputs: . (map) */}}
{{- define "collectors.rbac.groupRules" -}}
{{- $groups := dict }}
{{- range $key, $verbs := . }}
  {{- $parts := splitList "|" $key }}
  {{- $groupKey := printf "1|%s|%s" (index $parts 0) (join "," $verbs) }}
  {{- $item := index $parts 1 }}
  {{- if index $parts 2 }}
    {{- $groupKey = printf "2|%s|%s|%s" (index $parts 0) (index $parts 1) (join "," $verbs) }}
    {{- $item = index $parts 2 }}
  {{- end }}
  {{- $group := get $groups $groupKey | default (dict "parts" $parts "verbs" $verbs "items" (list)) }}
  {{- $_ := set $group "items" (append $group.items $item) }}
  {{- $_ := set $groups $groupKey $group }}
{{- end }}
{{- $rules := list }}
{{- range $groupKey, $group := $groups }}
  {{- if hasPrefix "1|" $groupKey }}
    {{- $rules = append $rules (dict "apiGroups" (list (index $group.parts 0)) "resources" $group.items "verbs" $group.verbs) }}
  {{- else }}
    {{- $rules = append $rules (dict "apiGroups" (list (index $group.parts 0)) "resources" (list (index $group.parts 1)) "resourceNames" $group.items "verbs" $group.verbs) }}
  {{- end }}
{{- end }}
{{- $rules | toYaml }}
{{- end }}

{{/* Inputs: name, namespace, labels, serviceAccountName, roles ({namespace: rules}) */}}
{{- define "collectors.rbac.render" }}
{{- $subjects := list (dict "kind" "ServiceAccount" "name" .serviceAccountName "namespace" .namespace) }}
{{- range $namespace, $rules := .roles }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ $.name }}
  namespace: {{ $namespace }}
  labels:
    {{- toYaml $.labels | nindent 4 }}
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

{{/* Inputs: Files, collectorValues, entries, name (instance fullname), namespace, labels, serviceAccountName */}}
{{- define "collectors.rbac.instance" }}
{{- if dig "rbac" "create" true .collectorValues }}
  {{- $catalog := .Files.Get "collectors/rbac-bundles.yaml" | fromYaml }}
  {{- $roles := dict }}
  {{- range $namespace, $rules := include "collectors.rbac.expand" (dict "catalog" $catalog "entries" .entries) | fromYaml }}
    {{- $_ := set $roles $namespace (include "collectors.rbac.groupRules" $rules | fromYamlArray) }}
  {{- end }}
  {{- $labels := merge (dict "app.kubernetes.io/component" "rbac" "app.kubernetes.io/instance" .name) .labels }}
  {{- include "collectors.rbac.render" (dict "name" (printf "%s-rbac" .name) "namespace" .namespace "labels" $labels "serviceAccountName" .serviceAccountName "roles" $roles) }}
{{- end }}
{{- end }}
