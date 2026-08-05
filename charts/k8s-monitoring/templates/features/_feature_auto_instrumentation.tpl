{{- define "features.autoInstrumentation.enabled" }}{{ .Values.autoInstrumentation.enabled }}{{- end }}

{{- define "features.autoInstrumentation.include" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- $destinations := include "features.autoInstrumentation.destinations" . | fromYamlArray }}
// Feature: Auto-Instrumentation
{{- include "feature.autoInstrumentation.module" (dict "Values" $.Values.autoInstrumentation "Files" $.Subcharts.autoInstrumentation.Files) }}
auto_instrumentation "feature" {
  metrics_destinations = [
    {{ include "pipeline.alloy.targets.forFeature" (dict "root" $ "featureKey" "autoInstrumentation" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- include "pipeline.alloy.feature.render.forFeature" (dict "root" $ "featureKey" "autoInstrumentation" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end -}}
{{- end -}}

{{- define "features.autoInstrumentation.validate" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- $featureKey := "autoInstrumentation" }}
{{- $featureName := "Auto-Instrumentation" }}
{{- $destinations := include "features.autoInstrumentation.destinations" . | fromYamlArray }}
{{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName "Values" $.Values "featureKey" $featureKey) }}
{{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" "autoInstrumentation" "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}
{{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
{{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
{{- include "features.autoInstrumentation.validate.beylaPortConflict" . }}
{{- end -}}
{{- end -}}

{{/*
Best-effort check for a host port conflict before Auto-Instrumentation deploys Beyla.
Beyla runs with hostNetwork enabled and binds its port on every node, so any DaemonSet that already binds the
same host port — whether another Beyla or an unrelated workload — will collide with it. This scans all
DaemonSets (not just Beyla-like ones) for one that binds the host port, either via an explicit `hostPort` or
via `hostNetwork` with a matching `containerPort`. A plain `containerPort` without `hostNetwork`/`hostPort` is
pod-local and does not conflict, so it is ignored. `lookup` returns nothing during `helm template`/`--dry-run`
(no cluster connection), so this check is skipped in those cases. If a conflict is found, recommend deploying
Beyla on a unique port.
*/}}
{{- define "features.autoInstrumentation.validate.beylaPortConflict" }}
{{- $beyla := .Values.autoInstrumentation.beyla | default dict }}
{{- if dig "portConflictCheck" true $beyla }}
  {{- $ourPort := dig "service" "targetPort" 9090 $beyla | int }}
  {{- $conflict := dict }}
  {{- range $daemonSet := (dig "items" list (lookup "apps/v1" "DaemonSet" "" "" | default dict)) }}
    {{- if not $conflict.found }}
      {{- $labels := $daemonSet.metadata.labels | default dict }}
      {{- /* Skip the Beyla managed by this release (relevant on upgrades) */}}
      {{- if ne (dig "app.kubernetes.io/instance" "" $labels) $.Release.Name }}
        {{- $dsHostNetwork := dig "spec" "template" "spec" "hostNetwork" false $daemonSet }}
        {{- range $container := (dig "spec" "template" "spec" "containers" (list) $daemonSet) }}
          {{- range $port := (dig "ports" (list) $container) }}
            {{- if or (eq (int (dig "hostPort" 0 $port)) $ourPort) (and $dsHostNetwork (eq (int (dig "containerPort" 0 $port)) $ourPort)) }}
              {{- $_ := set $conflict "found" true }}
              {{- $_ := set $conflict "namespace" $daemonSet.metadata.namespace }}
              {{- $_ := set $conflict "name" $daemonSet.metadata.name }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $conflict.found }}
    {{- $msg := list "" (printf "A workload already appears to bind host port %d on this cluster's nodes." $ourPort) }}
    {{- $msg = append $msg (printf "Found DaemonSet \"%s\" in namespace \"%s\"." $conflict.name $conflict.namespace) }}
    {{- $msg = append $msg "Beyla runs with hostNetwork enabled and binds this port on every node, so deploying it will cause a host port conflict." }}
    {{- $msg = append $msg "" }}
    {{- $msg = append $msg "Deploy Beyla on a different, unused port:" }}
    {{- $msg = append $msg "autoInstrumentation:" }}
    {{- $msg = append $msg "  beyla:" }}
    {{- $msg = append $msg "    service:" }}
    {{- $msg = append $msg "      targetPort: <unique-port>" }}
    {{- $msg = append $msg "" }}
    {{- $msg = append $msg "If this detection is incorrect, you can disable this check:" }}
    {{- $msg = append $msg "autoInstrumentation:" }}
    {{- $msg = append $msg "  beyla:" }}
    {{- $msg = append $msg "    portConflictCheck: false" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "features.autoInstrumentation.destinations" }}
{{- if .Values.autoInstrumentation.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.autoInstrumentation.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.autoInstrumentation.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.autoInstrumentation.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.autoInstrumentation.collector.values" }}{{- end -}}
