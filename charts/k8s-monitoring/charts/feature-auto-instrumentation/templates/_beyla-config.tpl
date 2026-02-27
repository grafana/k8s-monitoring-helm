{{- define "k8s-monitoring.beyla.config" -}}
{{- $beyla := .Values -}}
{{- if hasKey .Values "autoInstrumentation" }}
  {{- $beyla = .Values.autoInstrumentation.beyla -}}
{{- end }}
{{- $valuesMap := .Values | toYaml | fromYaml -}}
{{- $beylaMap := $beyla | toYaml | fromYaml -}}
{{- $config := (dig "config" "data" dict $beylaMap) | deepCopy -}}
{{- $clusterName := "" -}}
{{- if hasKey $valuesMap "cluster" }}
  {{- $clusterName = (dig "cluster" "name" "" $valuesMap) -}}
{{- else if hasKey $valuesMap "global" }}
  {{- $clusterName = (dig "global" "cluster" "name" "" $valuesMap) -}}
{{- end }}
{{- $attributes := dict "kubernetes" (dict "enable" true "cluster_name" $clusterName) -}}
{{- $targetPort := dig "service" "targetPort" (dig "config" "data" "prometheus_export" "port" 9090 $beylaMap) $beylaMap -}}
{{- $internalMetrics := dict "prometheus" (dict "port" $targetPort) -}}
{{- $prometheusExport := dict "port" $targetPort -}}
{{- $overrides := dict "attributes" $attributes "internal_metrics" $internalMetrics "prometheus_export" $prometheusExport -}}

{{- if and (eq (dig "preset" "" $beylaMap) "network") (not (hasKey $config "network")) }}
  {{- $overrides = merge $overrides (dict "network" (dict "enable" true)) -}}
{{- end }}
{{- if and (eq (dig "preset" "" $beylaMap) "application") (not (hasKey $config "discovery")) }}
  {{- $services := list (dict "k8s_namespace" ".") -}}
  {{- $excludeServices := list (dict "exe_path" ".*alloy.*|.*otelcol.*|.*beyla.*") -}}
  {{- $discovery := dict "services" $services "exclude_services" $excludeServices -}}
  {{- $overrides = merge $overrides (dict "discovery" $discovery) -}}
{{- end }}
{{- if and (dig "applicationObservability" "enabled" false $valuesMap) (dig "deliverTracesToApplicationObservability" false $beylaMap) }}
  {{- $endpoint := "" -}}
  {{- if dig "applicationObservability" "receivers" "otlp" "grpc" "enabled" false $valuesMap }}
    {{- $endpoint = include "features.applicationObservability.receiver.grpc" . | trim -}}
  {{- else if dig "applicationObservability" "receivers" "otlp" "http" "enabled" false $valuesMap }}
    {{- $endpoint = include "features.applicationObservability.receiver.http" . | trim -}}
  {{- end }}
  {{- if $endpoint }}
    {{- $overrides = merge $overrides (dict "otel_traces_export" (dict "endpoint" $endpoint)) -}}
  {{- end }}
{{- end }}

{{- merge $config $overrides | toYaml -}}
{{- end }}
