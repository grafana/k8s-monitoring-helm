{{- /* Builds the alloy config for otlp sampler */ -}}
{{- define "collectors.sampler.alloy" -}}
{{- $collectorValues := include "collector.alloy.values" . | fromYaml }}



{{- end }}
