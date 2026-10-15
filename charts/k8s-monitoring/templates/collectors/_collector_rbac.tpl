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

{{/* Reads the raw value of a block's top-level attribute, joining a list that spans several lines onto one line. Inputs: body, name. Output: the top-level attribute value, or "" if it isn't set */}}
{{- define "collectors.rbac.attribute" -}}
{{- $list := regexFind (printf `(?m)^\s*%s\s*=\s*\[[^\]]*\]` .name) .body }}
{{- $line := regexFind (printf `(?m)^\s*%s\s*=.*$` .name) .body }}
{{- if $list }}
  {{- regexReplaceAll (printf `(?s)^\s*%s\s*=\s*` .name) $list "" | replace "\n" " " }}
{{- else if $line }}
  {{- regexReplaceAll (printf `^\s*%s\s*=\s*(.*?)\s*$` .name) $line "${1}" }}
{{- end }}
{{- end }}

{{/* Unquotes a single string literal. The scanner only trusts literals for names and namespaces, because anything else is only known when Alloy runs. Inputs: value (raw attribute value). Output: the string, or "" if the value isn't a single string literal */}}
{{- define "collectors.rbac.literal" -}}
{{- if regexMatch `^"[^"\\]*"$` .value }}{{ trimAll "\"" .value }}{{ end }}
{{- end }}

{{/* Strips a block's header and closing brace, and empties its nested blocks, so attribute lookups only see the block's own attributes. Inputs: block (a block's text). Output: the block's body with nested blocks emptied */}}
{{- define "collectors.rbac.body" -}}
{{- $body := regexReplaceAll `^[^{]*\{` (trimSuffix "}" .block) "" }}
{{- range $_ := until 8 }}
  {{- $body = regexReplaceAll `\{[^{}]*\}` $body "{}" }}
{{- end }}
{{- $body }}
{{- end }}

{{/* Builds the regular expression for whole blocks with a name, including blocks nested up to the depth of nested, without matching the end of a longer name. Inputs: name (a regular expression for the block name), nested. Output: a regular expression for those blocks */}}
{{- define "collectors.rbac.blockPattern" -}}
{{- printf `(?:^|[^A-Za-z0-9_.])%s\s+"[^"]*"\s*\{%s\}` .name .nested }}
{{- end }}

{{/* Fails the render for configuration that minimal mode can't compute RBAC for, and says to set the collector's rbac.mode to alloy. Inputs: collectorName, valuesPath, problem. Fails the render. */}}
{{- define "collectors.rbac.unsupported" -}}
{{- $msg := list "" (printf "The %s collector %s, so rbac.mode: minimal can't compute its RBAC." .collectorName .problem) }}
{{- $msg = append $msg (printf "Please set %s.rbac.mode to \"alloy\"." (.valuesPath | default (printf "collectors.%s" .collectorName))) }}
{{- fail (join "\n" $msg) }}
{{- end }}

{{/* Splits a configuration into the top level and its declare blocks, nested ones included, so the scanner knows which module a component is in and can follow its module arguments. Fails when a declare block can't be read. Inputs: text, nested, context (for errors). Output: [{name, parent, text}], where text excludes nested declare blocks */}}
{{- define "collectors.rbac.scopes" -}}
{{- $scopes := list (dict "name" "" "parent" -1 "text" .text) }}
{{- $frontier := list 0 }}
{{- range $_ := until 8 }}
  {{- $next := list }}
  {{- range $index := $frontier }}
    {{- $scope := index $scopes $index }}
    {{- $own := $scope.text }}
    {{- range $block := regexFindAll (include "collectors.rbac.blockPattern" (dict "name" "declare" "nested" $.nested)) $scope.text -1 }}
      {{- $own = replace $block "\n" $own }}
      {{- $next = append $next (len $scopes) }}
      {{- $scopes = append $scopes (dict "name" (regexReplaceAll `^[^"]*"([^"]*)"(?s:.*)$` $block "${1}") "parent" $index "text" (regexReplaceAll `^[^{]*\{` (trimSuffix "}" $block) "")) }}
    {{- end }}
    {{- if regexMatch `(?:^|[^A-Za-z0-9_.])declare\s+"[^"]*"\s*\{` $own }}
      {{- include "collectors.rbac.unsupported" (merge (dict "problem" "has a declare block that can't be read, for example because of unbalanced braces") $.context) }}
    {{- end }}
    {{- $_ := set $scope "text" $own }}
  {{- end }}
  {{- $frontier = $next }}
{{- end }}
{{- $scopes | toYaml }}
{{- end }}

{{/* Lists the scopes that can call a module: the scope that declares it, and the scopes nested in that one, except a scope that declares its own module with the same name, which shadows it. Inputs: scopes, scope (the module's index). Output: scope indexes */}}
{{- define "collectors.rbac.callerScopes" -}}
{{- $module := index .scopes (int .scope) }}
{{- $shadowing := list }}
{{- range $candidate := .scopes }}
  {{- if eq $candidate.name $module.name }}{{ $shadowing = append $shadowing (int $candidate.parent) }}{{ end }}
{{- end }}
{{- $callers := list (int $module.parent) }}
{{- $frontier := $callers }}
{{- range $_ := until 8 }}
  {{- $next := list }}
  {{- range $index, $candidate := $.scopes }}
    {{- if and (has (int $candidate.parent) $frontier) (ne $candidate.name $module.name) (not (has $index $shadowing)) }}
      {{- $next = append $next $index }}
    {{- end }}
  {{- end }}
  {{- $callers = concat $callers $next }}
  {{- $frontier = $next }}
{{- end }}
{{- $callers | toYaml }}
{{- end }}

{{/* Follows a value that comes from a module argument, like argument.namespaces.value or coalesce(argument.namespaces.value, []), to the value that each call of the module passes, from any scope that can call it, through nested modules. A call that doesn't pass the argument gets the coalesce default. Inputs: value (raw attribute value), scopes, scope (index), nested, depth. Output: the possible values, with "?" for one that can't be found */}}
{{- define "collectors.rbac.argumentValues" -}}
{{- $values := list .value }}
{{- $pattern := `^(?:coalesce\(\s*)?argument\.([A-Za-z_][A-Za-z0-9_]*)\.value\s*(?:,\s*(?s:(.*?))\s*\))?$` }}
{{- if regexMatch $pattern .value }}
  {{- $argument := regexReplaceAll $pattern .value "${1}" }}
  {{- $default := ternary (regexReplaceAll $pattern .value "${2}") "null" (hasPrefix "coalesce(" .value) }}
  {{- $scope := index .scopes (int .scope) }}
  {{- $values = list "?" }}
  {{- if and (ge (int $scope.parent) 0) (lt (int .depth) 8) }}
    {{- $callPattern := include "collectors.rbac.blockPattern" (dict "name" (regexQuoteMeta $scope.name) "nested" .nested) }}
    {{- $found := list }}
    {{- range $caller := include "collectors.rbac.callerScopes" (dict "scopes" .scopes "scope" .scope) | fromYamlArray }}
      {{- range $call := regexFindAll $callPattern (index $.scopes (int $caller)).text -1 }}
        {{- $value := include "collectors.rbac.attribute" (dict "body" (include "collectors.rbac.body" (dict "block" $call)) "name" $argument) }}
        {{- if or (not $value) (and (regexMatch `^\[\s*\]$` $value) (ne $default "null")) }}{{ $value = $default }}{{ end }}
        {{- $found = concat $found (include "collectors.rbac.argumentValues" (dict "value" $value "scopes" $.scopes "scope" $caller "nested" $.nested "depth" (add1 (int $.depth))) | fromYamlArray) }}
      {{- end }}
    {{- end }}
    {{- if $found }}{{ $values = $found }}{{ end }}
  {{- end }}
{{- end }}
{{- $values | toYaml }}
{{- end }}

{{/* Combines list values into the namespaces a component reads: a list of string literals adds its namespaces, plus own for discovery.kubernetes' own_namespace, and an empty list or any other value means every namespace. Inputs: values (raw list values), own (a namespace to add to each list). Output: the namespaces, or [] for every namespace */}}
{{- define "collectors.rbac.namespaceLists" -}}
{{- $namespaces := list }}
{{- $all := not .values }}
{{- range $value := .values }}
  {{- $list := list }}
  {{- if regexMatch `^\[\s*("[^"\\]*"\s*,\s*)*("[^"\\]*"\s*,?\s*)?\]$` $value }}
    {{- range $item := regexFindAll `"[^"\\]*"` $value -1 }}
      {{- $list = append $list (trimAll "\"" $item) }}
    {{- end }}
    {{- with $.own }}{{ $list = append $list . }}{{ end }}
  {{- end }}
  {{- if $list }}{{ $namespaces = concat $namespaces $list }}{{ else }}{{ $all = true }}{{ end }}
{{- end }}
{{- ternary (list) $namespaces $all | uniq | toYaml }}
{{- end }}

{{/* Reads the one namespace that a component is limited to, from a string that can come from a module argument: a k8sattributes filter's namespace, or the namespace in a load balancer's "<service>.<namespace>", which defaults to the release namespace. Inputs: value (raw string value), context (for argumentValues), service (read the namespace from "<service>.<namespace>"), releaseNamespace. Output: the namespaces, or [] for every namespace */}}
{{- define "collectors.rbac.namespaceString" -}}
{{- $lists := list }}
{{- range $value := include "collectors.rbac.argumentValues" (merge (dict "value" .value) .context) | fromYamlArray }}
  {{- $namespace := include "collectors.rbac.literal" (dict "value" $value) }}
  {{- if and $.service $namespace }}
    {{- $namespace = ternary (regexReplaceAll `^[^.]*\.([^.]+).*$` $namespace "${1}") $.releaseNamespace (regexMatch `^[^.]*\.[^.]+` $namespace) }}
  {{- end }}
  {{- $lists = append $lists (ternary (printf "[%q]" $namespace) "" (ne $namespace "")) }}
{{- end }}
{{- include "collectors.rbac.namespaceLists" (dict "values" $lists) }}
{{- end }}

{{/* Reads the namespaces that a component is limited to, the way its catalog entry's scope says to read them. Inputs: scope ("namespacesBlock", "namespacesAttribute", "filterNamespace", "kubernetesService", "ownNamespace", or "targets"), block, releaseNamespace, scopes, scopeIndex, scopeText, nested. Output: the namespaces, or [] for every namespace */}}
{{- define "collectors.rbac.scope" -}}
{{- $context := dict "scopes" .scopes "scope" .scopeIndex "nested" .nested "depth" 0 }}
{{- $body := include "collectors.rbac.body" (dict "block" .block) }}
{{- $namespaces := list }}
{{- if eq .scope "namespacesBlock" }}
  {{- with regexFind `namespaces\s*\{[^{}]*\}` (regexReplaceAll `^[^{]*\{` .block "") }}
    {{- $blockBody := trimSuffix "}" (regexReplaceAll `^namespaces\s*\{` . "") }}
    {{- $own := ternary $.releaseNamespace "" (regexMatch `own_namespace\s*=\s*true` $blockBody) }}
    {{- with include "collectors.rbac.attribute" (dict "body" $blockBody "name" "names") }}
      {{- $namespaces = include "collectors.rbac.namespaceLists" (dict "values" (include "collectors.rbac.argumentValues" (merge (dict "value" .) $context) | fromYamlArray) "own" $own) | fromYamlArray }}
    {{- else }}
      {{- $namespaces = compact (list $own) }}
    {{- end }}
  {{- end }}
{{- else if eq .scope "namespacesAttribute" }}
  {{- with include "collectors.rbac.attribute" (dict "body" $body "name" "namespaces") }}
    {{- $namespaces = include "collectors.rbac.namespaceLists" (dict "values" (include "collectors.rbac.argumentValues" (merge (dict "value" .) $context) | fromYamlArray)) | fromYamlArray }}
  {{- end }}
{{- else if eq .scope "filterNamespace" }}
  {{- $filter := regexFind `filter\s*\{(?:[^{}]|\{[^{}]*\})*\}` .block }}
  {{- $filterBody := regexReplaceAll `\{[^{}]*\}` (trimSuffix "}" (regexReplaceAll `^filter\s*\{` $filter "")) "{}" }}
  {{- with include "collectors.rbac.attribute" (dict "body" $filterBody "name" "namespace") }}
    {{- $namespaces = include "collectors.rbac.namespaceString" (dict "value" . "context" $context) | fromYamlArray }}
  {{- end }}
{{- else if eq .scope "kubernetesService" }}
  {{- $kubernetes := regexFind `kubernetes\s*\{[^{}]*\}` (regexFind `resolver\s*\{(?:[^{}]|\{[^{}]*\})*\}` .block) }}
  {{- with include "collectors.rbac.attribute" (dict "body" (trimSuffix "}" (regexReplaceAll `^kubernetes\s*\{` $kubernetes "")) "name" "service") }}
    {{- $namespaces = include "collectors.rbac.namespaceString" (dict "value" . "context" $context "service" true "releaseNamespace" $.releaseNamespace) | fromYamlArray }}
  {{- end }}
{{- else if eq .scope "ownNamespace" }}
  {{- $namespaces = list .releaseNamespace }}
{{- else if eq .scope "targets" }}
  {{- $all := false }}
  {{- range $source := include "collectors.rbac.targetSources" (dict "block" .block "text" .scopeText "nested" .nested) | fromYamlArray }}
    {{- $sourceNamespaces := list }}
    {{- if hasPrefix "discovery.kubernetes" $source.block }}
      {{- $sourceNamespaces = include "collectors.rbac.scope" (merge (dict "scope" "namespacesBlock" "block" $source.block) $) | fromYamlArray }}
    {{- end }}
    {{- if $sourceNamespaces }}{{ $namespaces = concat $namespaces $sourceNamespaces }}{{ else }}{{ $all = true }}{{ end }}
  {{- end }}
  {{- if $all }}{{ $namespaces = list }}{{ end }}
{{- end }}
{{- $namespaces | uniq | toYaml }}
{{- end }}

{{/* Follows a component's targets back through discovery.relabel blocks to the discovery components or static targets they come from, so a scrape that sends the ServiceAccount token can be matched to what it scrapes, by the discovery role and the relabel rules on the way. Inputs: block, text (the scope's text), nested. Output: [{block, path}] for each source of targets: the source block (or "" if it can't be followed), and the text of every block on the way */}}
{{- define "collectors.rbac.targetSources" -}}
{{- $sources := list }}
{{- $frontier := list (dict "block" .block "path" .block) }}
{{- range $_ := until 8 }}
  {{- $next := list }}
  {{- range $item := $frontier }}
    {{- $body := include "collectors.rbac.body" (dict "block" $item.block) }}
    {{- $references := regexFindAll `[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*\.(?:output|targets)\b` $body -1 }}
    {{- range $reference := $references }}
      {{- $kind := regexReplaceAll `\.[A-Za-z0-9_]+\.(?:output|targets)$` $reference "" }}
      {{- $label := regexReplaceAll `^.*\.([A-Za-z0-9_]+)\.(?:output|targets)$` $reference "${1}" }}
      {{- $source := "" }}
      {{- if regexMatch `^(discovery|prometheus\.exporter)\.` $kind }}
        {{- $source = regexFind (printf `(?:^|[^A-Za-z0-9_.])%s\s+"%s"\s*\{%s\}` (regexQuoteMeta $kind) $label $.nested) $.text }}
        {{- $source = regexReplaceAll `^[^A-Za-z_]+` $source "" }}
      {{- end }}
      {{- if and $source (eq $kind "discovery.relabel") }}
        {{- $next = append $next (dict "block" $source "path" (printf "%s\n%s" $item.path $source)) }}
      {{- else }}
        {{- $sources = append $sources (dict "block" $source "path" (ternary (printf "%s\n%s" $item.path (include "collectors.rbac.body" (dict "block" $source))) "" (ne $source ""))) }}
      {{- end }}
    {{- end }}
    {{- if not $references }}
      {{- $static := regexMatch `^\[` (include "collectors.rbac.attribute" (dict "body" $body "name" "targets")) }}
      {{- $sources = append $sources (dict "block" (ternary $item.block "" $static) "path" (ternary $item.path "" $static)) }}
    {{- else if regexMatch `[\[,(]\s*\{` $body }}
      {{- $sources = append $sources (dict "block" $item.block "path" $item.path) }}
    {{- end }}
  {{- end }}
  {{- $frontier = $next }}
{{- end }}
{{- range $_ := $frontier }}{{ $sources = append $sources (dict "block" "" "path" "") }}{{ end }}
{{- $sources | toYaml }}
{{- end }}

{{/* Finds the catalog's components in a final config, one declare scope at a time, and returns the bundles they need, with the namespaces and object names they're limited to. Comments are removed first, and braces in strings are masked so they don't count as blocks. Inputs: components (collectors/alloy-kubernetes-api.yaml), text (final config), releaseNamespace, collectorName, valuesPath. Output: [{bundle, namespaces, resourceNames}] */}}
{{- define "collectors.rbac.scan" -}}
{{- $entries := list }}
{{- $tick := printf "%c" 96 }}
{{- $strings := printf `"(?:[^"\\]|\\.)*"|%s[^%s]*%s` $tick $tick $tick }}
{{- $text := regexReplaceAll (printf `(%s)|//[^\n]*|/\*(?s:.*?)\*/` $strings) .text "${1}" }}
{{- range $literal := regexFindAll $strings $text -1 }}
  {{- if regexMatch `[{}]` $literal }}
    {{- $text = replace $literal ($literal | replace "{" "(" | replace "}" ")") $text }}
  {{- end }}
{{- end }}
{{- $nested := `[^{}]*` }}
{{- range $_ := until 8 }}
  {{- $nested = printf `(?:[^{}]|\{%s\})*` $nested }}
{{- end }}
{{- $known := dict }}
{{- range $item := .components }}{{ $_ := set $known $item.component true }}{{ end }}
{{- $context := dict "collectorName" .collectorName "valuesPath" .valuesPath }}
{{- $scopes := include "collectors.rbac.scopes" (dict "text" $text "nested" $nested "context" $context) | fromYamlArray }}
{{- range $scopeIndex, $scope := $scopes }}
  {{- $matched := dict }}
  {{- range $item := $.components }}
    {{- $name := regexQuoteMeta $item.component }}
    {{- $blocks := regexFindAll (include "collectors.rbac.blockPattern" (dict "name" $name "nested" $nested)) $scope.text -1 }}
    {{- if gt (len (regexFindAll (printf `(?:^|[^A-Za-z0-9_.])%s\s+"[^"]*"\s*\{` $name) $scope.text -1)) (len $blocks) }}
      {{- include "collectors.rbac.unsupported" (merge (dict "problem" (printf "has a %s block that can't be read, for example because of unbalanced braces" $item.component)) $context) }}
    {{- end }}
    {{- range $block := $blocks }}
      {{- $block = regexReplaceAll `^[^A-Za-z_]+` $block "" }}
      {{- $inner := regexReplaceAll `^[^{]*\{` $block "" }}
      {{- $applies := not (and $item.unless (regexMatch (printf "(?s)%s" $item.unless) $inner)) }}
      {{- range $pattern := ternary $item.match (list ($item.match | default "")) (kindIs "slice" $item.match) }}
        {{- if not (regexMatch (printf "(?s)%s" $pattern) $inner) }}{{ $applies = false }}{{ end }}
      {{- end }}
      {{- if $applies }}
        {{- $_ := set $matched $block true }}
        {{- $body := include "collectors.rbac.body" (dict "block" $block) }}
        {{- if $item.namedObject }}
          {{- $objectName := include "collectors.rbac.literal" (dict "value" (include "collectors.rbac.attribute" (dict "body" $body "name" "name"))) }}
          {{- $namespace := include "collectors.rbac.literal" (dict "value" (include "collectors.rbac.attribute" (dict "body" $body "name" "namespace"))) }}
          {{- $entries = append $entries (dict "bundle" $item.namedObject "namespaces" (compact (list $namespace)) "resourceNames" (compact (list $objectName))) }}
        {{- else }}
          {{- $namespaces := $item.namespaces | default list }}
          {{- if and $item.scope (not $item.namespaces) }}
            {{- $namespaces = include "collectors.rbac.scope" (dict "scope" $item.scope "block" $block "releaseNamespace" $.releaseNamespace "scopes" $scopes "scopeIndex" $scopeIndex "scopeText" $scope.text "nested" $nested) | fromYamlArray }}
          {{- end }}
          {{- $bundles := $item.bundles | default list }}
          {{- if $item.roles }}
            {{- $role := include "collectors.rbac.attribute" (dict "body" $body "name" "role") }}
            {{- $bundles = get $item.roles (include "collectors.rbac.literal" (dict "value" $role)) | default list }}
            {{- if and $role (not $bundles) }}
              {{- range $_, $roleBundles := $item.roles }}{{ $bundles = concat $bundles $roleBundles }}{{ end }}
              {{- $namespaces = list }}
            {{- end }}
          {{- end }}
          {{- range $bundle := $bundles | uniq }}
            {{- $entries = append $entries (dict "bundle" $bundle "namespaces" $namespaces) }}
          {{- end }}
          {{- range $bundle := $item.clusterBundles | default list }}
            {{- $entries = append $entries (dict "bundle" $bundle) }}
          {{- end }}
          {{- if $item.targets }}
            {{- range $source := include "collectors.rbac.targetSources" (dict "block" $block "text" $scope.text "nested" $nested) | fromYamlArray }}
              {{- $rule := dict }}
              {{- range $candidate := $item.targets }}
                {{- if and $source.path (not $rule) (or (not $candidate.match) (regexMatch (printf "(?s)%s" ($candidate.match | default "")) $source.path)) }}{{ $rule = $candidate }}{{ end }}
              {{- end }}
              {{- if not $source.path }}
                {{- include "collectors.rbac.unsupported" (merge (dict "problem" (printf "has a %s block that uses the ServiceAccount token, and where its targets come from can't be followed" $item.component)) $context) }}
              {{- else if not $rule }}
                {{- include "collectors.rbac.unsupported" (merge (dict "problem" (printf "has a %s block that sends the ServiceAccount token to targets that minimal RBAC doesn't support" $item.component)) $context) }}
              {{- end }}
              {{- range $bundle := $rule.bundles | default list }}
                {{- $entries = append $entries (dict "bundle" $bundle) }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- range $block := regexFindAll (include "collectors.rbac.blockPattern" (dict "name" `[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+` "nested" $nested)) $scope.text -1 }}
    {{- $block = regexReplaceAll `^[^A-Za-z_]+` $block "" }}
    {{- $component := regexReplaceAll `^([A-Za-z0-9_.]+)(?s:.*)$` $block "${1}" }}
    {{- if hasPrefix "import." $component }}
      {{- include "collectors.rbac.unsupported" (merge (dict "problem" (printf "uses %s, which loads configuration that can't be scanned" $component)) $context) }}
    {{- end }}
    {{- if and (regexMatch `kubernetes|kubelet|k8s` $component) (not (hasKey $known $component)) }}
      {{- include "collectors.rbac.unsupported" (merge (dict "problem" (printf "uses %s, which minimal RBAC doesn't know about" $component)) $context) }}
    {{- end }}
    {{- if and (contains "/var/run/secrets/kubernetes.io/serviceaccount/token" $block) (not (hasKey $matched $block)) }}
      {{- include "collectors.rbac.unsupported" (merge (dict "problem" (printf "has a %s block that uses the ServiceAccount token" $component)) $context) }}
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

{{/* Computes an instance's resolved rules: the entries from scanning its final config, plus the rules from values. Inputs: Files, config (final config), entries (rules from values), releaseNamespace, collectorName, valuesPath. Output: {cluster, namespaced} */}}
{{- define "collectors.rbac.compute" -}}
{{- $catalog := .Files.Get "collectors/rbac-bundles.yaml" | fromYaml }}
{{- $components := .Files.Get "collectors/alloy-kubernetes-api.yaml" | fromYamlArray }}
{{- $scanned := include "collectors.rbac.scan" (dict "components" $components "text" .config "releaseNamespace" .releaseNamespace "collectorName" .collectorName "valuesPath" .valuesPath) | fromYamlArray }}
{{- include "collectors.rbac.resolve" (dict "catalog" $catalog "entries" (concat (.entries | default list) $scanned)) }}
{{- end }}

{{/* Renders the RBAC objects of one collector, sampler, or service graph instance in minimal mode, from its final config, unless its rbac.create is false. Inputs: root, values (root-like with collectorName), alloyValues (the collector.alloy.values result), config (final config), entries (optional, rules from values), valuesPath (optional) */}}
{{- define "collectors.rbac.instance" }}
{{- if dig "rbac" "create" true .alloyValues }}
  {{- $name := include "collector.alloy.fullname" .values }}
  {{- $namespace := include "helper.namespace" .root }}
  {{- $serviceAccountName := include "collector.alloy.serviceAccountName" (merge (dict "alloyValues" .alloyValues) .values) }}
  {{- $resolved := include "collectors.rbac.compute" (dict "Files" .root.Files "config" .config "entries" .entries "releaseNamespace" $namespace "collectorName" .values.collectorName "valuesPath" .valuesPath) | fromYaml }}
  {{- $labels := merge (dict "app.kubernetes.io/component" "rbac" "app.kubernetes.io/instance" $name) (include "collector.alloy.labels" .root | fromYaml) }}
  {{- include "collectors.rbac.render" (dict "name" $name "namespace" $namespace "labels" $labels "serviceAccountName" $serviceAccountName "resolved" $resolved) }}
{{- end }}
{{- end }}
