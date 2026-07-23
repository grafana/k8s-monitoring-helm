{{/*
Best-effort check for another Alloy Operator already running in the cluster when deploying the bundled one.
Uses `lookup` to find Deployments that look like an Alloy Operator. `lookup` returns nothing during
`helm template`/`--dry-run` (no cluster connection), so this check is skipped in those cases.

The Alloy Operator watches the namespaced `Alloy` custom resources this chart creates. Two operators that
watch overlapping namespaces will compete to reconcile the same instances. An operator's scope is derived
from the `WATCH_NAMESPACE` environment variable on its Deployment: present and non-empty means it is
restricted to those namespaces (namespace-scoped); absent means it watches the whole cluster (cluster-scoped).

Conflict rules (only when we deploy our own operator):
  - Another cluster-scoped operator always conflicts (it watches every namespace, including ours).
  - Another namespace-scoped operator conflicts only when ours is cluster-scoped (ours then watches theirs).
This validation does not attempt to detect conflicts between two namespace-scoped operators that watch overlapping namespaces.
*/}}
{{- define "alloyOperator.validate" }}
{{- $op := index .Values "alloy-operator" }}
{{- if and $op.deploy $op.conflictCheck }}
  {{- $ourClusterScoped := and (not (dig "ownNamespaceOnly" false $op)) (empty (dig "namespaces" (list) $op)) }}
  {{- $conflict := dict }}
  {{- range $deploy := (lookup "apps/v1" "Deployment" "" "").items }}
    {{- if not $conflict.found }}
      {{- $labels := $deploy.metadata.labels | default dict }}
      {{- /* Skip the Alloy Operator managed by this release (relevant on upgrades) */}}
      {{- if ne (dig "app.kubernetes.io/instance" "" $labels) $.Release.Name }}
        {{- $nameLabel := dig "app.kubernetes.io/name" "" $labels }}
        {{- $isOperator := regexMatch "alloy[-_]operator" $nameLabel }}
        {{- range $container := (dig "spec" "template" "spec" "containers" (list) $deploy) }}
          {{- if regexMatch "alloy[-_]operator" (dig "image" "" $container) }}
            {{- $isOperator = true }}
          {{- end }}
        {{- end }}

        {{- if $isOperator }}
          {{- /* Cluster-scoped unless a non-empty WATCH_NAMESPACE env var restricts it */}}
          {{- $otherClusterScoped := true }}
          {{- range $container := (dig "spec" "template" "spec" "containers" (list) $deploy) }}
            {{- range $env := (dig "env" (list) $container) }}
              {{- if and (eq (dig "name" "" $env) "WATCH_NAMESPACE") (ne (dig "value" "" $env) "") }}
                {{- $otherClusterScoped = false }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if or $otherClusterScoped $ourClusterScoped }}
            {{- $msg := list "" "Another Alloy Operator appears to be running in this cluster." }}
            {{- $msg = append $msg (printf "Found Deployment \"%s\" in namespace \"%s\" running at %s scope." $deploy.metadata.name $deploy.metadata.namespace (ternary "cluster" "namespace" $otherClusterScoped)) }}
            {{- $msg = append $msg "Two overlapping Alloy Operators will compete to manage the same Alloy instances, causing conflicting reconciliation." }}
            {{- $msg = append $msg "" }}
            {{- $msg = append $msg "Option 1: Don't deploy the bundled Alloy Operator and rely on the existing one:" }}
            {{- $msg = append $msg "alloy-operator:" }}
            {{- $msg = append $msg "  deploy: false" }}
            {{- if and $otherClusterScoped $ourClusterScoped }}
              {{- /* The other operator is cluster-scoped, so restricting ours doesn't remove the overlap */}}
              {{- $msg = append $msg "" }}
              {{- $msg = append $msg "Restricting this Alloy Operator to its own namespace will not help, since the existing operator is cluster-scoped and would still manage Alloy instances in every namespace." }}
            {{- else if $ourClusterScoped }}
              {{- $msg = append $msg "" }}
              {{- $msg = append $msg "Option 2: Restrict this Alloy Operator to its own namespace so the two don't overlap:" }}
              {{- $msg = append $msg "alloy-operator:" }}
              {{- $msg = append $msg "  ownNamespaceOnly: true" }}
            {{- end }}
            {{- $msg = append $msg "" }}
            {{- $msg = append $msg "If this detection is incorrect, you can disable this check:" }}
            {{- $msg = append $msg "alloy-operator:" }}
            {{- $msg = append $msg "  conflictCheck: false" }}
            {{- fail (join "\n" $msg) }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
