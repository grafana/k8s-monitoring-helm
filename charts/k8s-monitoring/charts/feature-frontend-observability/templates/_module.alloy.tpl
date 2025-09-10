{{- define "feature.frontendObservability.module" }}
declare "frontend_observability" {
  argument "logs_destinations" {
    comment = "Must be a list of log destinations where collected logs should be forwarded to"
  }

  argument "traces_destinations" {
    comment = "Must be a list of trace destinations where collected trace should be forwarded to"
  }

{{- $pipeline := include "feature.frontendObservability.pipeline" . | fromYamlArray }}
{{- range $component := $pipeline }}
  {{- $args := (dict "Values" $.Values "name" $component.name) }}

  {{- range $dataType := (list "logs" "traces")}}
    {{- if kindIs "string" (index $component.targets $dataType) }}
      {{- $args = merge $args (dict $dataType (index $component.targets $dataType)) }}
    {{- else if kindIs "slice" (index $component.targets $dataType) }}
      {{- $targets := list }}
      {{- range $target := (index $component.targets $dataType) }}
        {{- $targets = append $targets (include (printf "feature.frontendObservability.%s.alloy.target" $target.component) $target) }}
      {{- end }}
      {{- $args = merge $args (dict $dataType (printf "[%s]" (join ", " $targets))) }}
    {{- end }}
  {{- end }}

  // {{ $component.description | trim }}
  {{- include (printf "feature.frontendObservability.%s.alloy" $component.component) $args | indent 2 }}
{{- end }}
}
{{- end }}

{{- define "feature.frontendObservability.alloyModules" }}{{- end }}
