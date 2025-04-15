{{- define "features.applicationObservability.enabled" }}{{ .Values.applicationObservability.enabled }}{{- end }}

{{- define "features.applicationObservability.collectors" }}
{{- if .Values.applicationObservability.enabled -}}
- {{ .Values.applicationObservability.collector }}
{{- end }}
{{- end }}

{{- define "features.applicationObservability.include" }}
{{- if .Values.applicationObservability.enabled -}}
{{- $destinations := include "features.applicationObservability.destinations" . | fromYamlArray }}

// Feature: Application Observability
{{- include "feature.applicationObservability.module" (dict "Values" $.Values.applicationObservability "Files" $.Subcharts.applicationObservability.Files) }}
application_observability "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "otlp") | indent 4 | trim }}
  ]
  logs_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "logs" "ecosystem" "otlp") | indent 4 | trim }}
  ]
  traces_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "traces" "ecosystem" "otlp") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.applicationObservability.destinations" }}
{{- if .Values.applicationObservability.enabled -}}
{{- $metricsDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- $logDestinations     := include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs"    "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- $traceDestinations   := include "destinations.get" (dict "destinations" $.Values.destinations "type" "traces"  "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- concat $metricsDestinations $logDestinations $traceDestinations | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.applicationObservability.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.applicationObservability.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "otlp" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.applicationObservability.collector.values" }}
{{- if .Values.applicationObservability.enabled -}}
{{- $values := dict }}
{{- range $collector := include "features.applicationObservability.collectors" . | fromYamlArray }}
  {{- $extraPorts := deepCopy (dig "alloy" "extraPorts" list (index $.Values $collector)) }}
  {{- if $.Values.applicationObservability.receivers.otlp.grpc.enabled }}
    {{- if eq (include "collectors.has_extra_port" (deepCopy $ | merge (dict "name" $collector "portNumber" $.Values.applicationObservability.receivers.otlp.grpc.port))) "false" }}
      {{- $extraPorts = append $extraPorts (dict "name" "otlp-grpc" "port" $.Values.applicationObservability.receivers.otlp.grpc.port "targetPort" $.Values.applicationObservability.receivers.otlp.grpc.port "protocol" "TCP") }}
    {{- end -}}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.otlp.http.enabled }}
    {{- if eq (include "collectors.has_extra_port" (deepCopy $ | merge (dict "name" $collector "portNumber" $.Values.applicationObservability.receivers.otlp.http.port))) "false" }}
      {{- $extraPorts = append $extraPorts (dict "name" "otlp-http" "port" $.Values.applicationObservability.receivers.otlp.http.port "targetPort" $.Values.applicationObservability.receivers.otlp.http.port "protocol" "TCP") }}
    {{- end -}}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.zipkin.enabled }}
    {{- if eq (include "collectors.has_extra_port" (deepCopy $ | merge (dict "name" $collector "portNumber" $.Values.applicationObservability.receivers.zipkin.port))) "false" }}
      {{- $extraPorts = append $extraPorts (dict "name" "zipkin" "port" $.Values.applicationObservability.receivers.zipkin.port "targetPort" $.Values.applicationObservability.receivers.zipkin.port "protocol" "TCP") }}
    {{- end -}}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.jaeger.grpc.enabled }}
    {{- if eq (include "collectors.has_extra_port" (deepCopy $ | merge (dict "name" $collector "portNumber" $.Values.applicationObservability.receivers.jaeger.grpc.port))) "false" }}
      {{- $extraPorts = append $extraPorts (dict "name" "jaeger-grpc" "port" $.Values.applicationObservability.receivers.jaeger.grpc.port "targetPort" $.Values.applicationObservability.receivers.jaeger.grpc.port "protocol" "TCP") }}
    {{- end -}}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.jaeger.thriftBinary.enabled }}
    {{- if eq (include "collectors.has_extra_port" (deepCopy $ | merge (dict "name" $collector "portNumber" $.Values.applicationObservability.receivers.jaeger.thriftBinary.port))) "false" }}
      {{- $extraPorts = append $extraPorts (dict "name" "jaeger-binary" "port" $.Values.applicationObservability.receivers.jaeger.thriftBinary.port "targetPort" $.Values.applicationObservability.receivers.jaeger.thriftBinary.port "protocol" "TCP") }}
    {{- end -}}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.jaeger.thriftCompact.enabled }}
    {{- if eq (include "collectors.has_extra_port" (deepCopy $ | merge (dict "name" $collector "portNumber" $.Values.applicationObservability.receivers.jaeger.thriftCompact.port))) "false" }}
      {{- $extraPorts = append $extraPorts (dict "name" "jaeger-compact" "port" $.Values.applicationObservability.receivers.jaeger.thriftCompact.port "targetPort" $.Values.applicationObservability.receivers.jaeger.thriftCompact.port "protocol" "TCP") }}
    {{- end -}}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.jaeger.thriftHttp.enabled }}
    {{- if eq (include "collectors.has_extra_port" (deepCopy $ | merge (dict "name" $collector "portNumber" $.Values.applicationObservability.receivers.jaeger.thriftHttp.port))) "false" }}
      {{- $extraPorts = append $extraPorts (dict "name" "jaeger-http" "port" $.Values.applicationObservability.receivers.jaeger.thriftHttp.port "targetPort" $.Values.applicationObservability.receivers.jaeger.thriftHttp.port "protocol" "TCP") }}
    {{- end -}}
  {{- end -}}

  {{- $values = $values | merge (dict $collector (dict "alloy" (dict "extraPorts" $extraPorts))) }}
{{- end -}}
{{- $values | toYaml }}
{{- end -}}
{{- end -}}

{{- define "features.applicationObservability.validate" }}
{{- if .Values.applicationObservability.enabled -}}
{{- $featureName := "Application Observability" }}
{{- if .Values.applicationObservability.metrics.enabled -}}
{{- $metricDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- include "destinations.validate_destination_list" (dict "destinations" $metricDestinations "type" "metrics" "ecosystem" "otlp" "feature" $featureName) }}
{{- end -}}

{{- if .Values.applicationObservability.logs.enabled -}}
{{- $logDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "logs" "ecosystem" "loki" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- include "destinations.validate_destination_list" (dict "destinations" $logDestinations "type" "logs" "ecosystem" "loki" "feature" $featureName) }}
{{- end -}}

{{- if .Values.applicationObservability.traces.enabled -}}
{{- $traceDestinations := include "destinations.get" (dict "destinations" $.Values.destinations "type" "traces" "ecosystem" "otlp" "filter" $.Values.applicationObservability.destinations) | fromYamlArray -}}
{{- include "destinations.validate_destination_list" (dict "destinations" $traceDestinations "type" "traces" "ecosystem" "otlp" "feature" $featureName) }}
{{- end -}}

{{- range $collector := include "features.applicationObservability.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
  {{- if $.Values.applicationObservability.receivers.otlp.grpc.enabled }}
    {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.otlp.grpc.port "portName" "otlp-grpc" "portProtocol" "TCP") }}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.otlp.http.enabled }}
    {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.otlp.http.port "portName" "otlp-http" "portProtocol" "TCP") }}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.zipkin.enabled }}
    {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.zipkin.port "portName" "zipkin" "portProtocol" "TCP") }}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.jaeger.grpc.enabled }}
    {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.jaeger.grpc.port "portName" "jaeger-grpc" "portProtocol" "TCP") }}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.jaeger.thriftBinary.enabled }}
    {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.jaeger.thriftBinary.port "portName" "jaeger-binary" "portProtocol" "TCP") }}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.jaeger.thriftCompact.enabled }}
    {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.jaeger.thriftCompact.port "portName" "jaeger-compact" "portProtocol" "TCP") }}
  {{- end -}}
  {{- if $.Values.applicationObservability.receivers.jaeger.thriftHttp.enabled }}
    {{- include "collectors.require_extra_port" (dict "Values" $.Values "name" $collector "feature" $featureName "portNumber" $.Values.applicationObservability.receivers.jaeger.thriftHttp.port "portName" "jaeger-http" "portProtocol" "TCP") }}
  {{- end -}}
  {{- include "feature.applicationObservability.validate" (dict "Values" $.Values.applicationObservability) }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "features.applicationObservability.receiver.grpc" }}
  {{- if and .Values.applicationObservability.enabled .Values.applicationObservability.receivers.otlp.grpc.enabled }}
http://{{ include "collector.alloy.fullname" (deepCopy $ | merge (dict "collectorName" .Values.applicationObservability.collector)) }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.applicationObservability.receivers.otlp.grpc.port }}
  {{- end }}
{{- end }}
{{- define "features.applicationObservability.receiver.http" }}
  {{- if and .Values.applicationObservability.enabled .Values.applicationObservability.receivers.otlp.http.enabled }}
http://{{ include "collector.alloy.fullname" (deepCopy $ | merge (dict "collectorName" .Values.applicationObservability.collector)) }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.applicationObservability.receivers.otlp.http.port }}
  {{- end }}
{{- end }}
