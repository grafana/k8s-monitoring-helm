{{/* Returns the alloy reference(s) a feature's module should forward to for the given
     (type, ecosystem). Two modes:

       - No processors applicable to the feature's (type, ecosystem) → emits destination
         receivers exactly as today (delegates to destinations.alloy.targets), so features
         that don't use processors keep their current rendered output.

       - One or more processors applicable → emits a single ref: the chart-generated
         stamper input for (feature, type, ecosystem). The stamper labels each record with
         `selected_destinations` and forwards into the first processor in the chain. Chain
         bridges and per-destination gates are owned by the orchestrator.

     Inputs: root (.), featureKey (string), destinationNames ([]string), type, ecosystem. */}}
{{- define "pipeline.alloy.targets.forFeature" -}}
{{- $dp := default dict .root.Values.dataProcessors -}}
{{- $chosenDataProcessors := dig "dataProcessors" list (default dict (get .root.Values .featureKey)) }}
{{- /* Resolve the chain for THIS (type, ecosystem). Only route through a stamper when at
       least one chosen processor actually supports this tuple; otherwise the stamper ref
       would be emitted here but never rendered by feature.render.forFeature (which branches
       on the same resolved chain), leaving a dangling Alloy reference. */}}
{{- $chain := include "dataProcessors.get" (dict "dataProcessors" $dp "chosen" $chosenDataProcessors "type" .type "ecosystem" .ecosystem) | fromYamlArray -}}
{{- if empty $chain -}}
{{- include "destinations.alloy.targets" (dict "destinations" .root.Values.destinations "destinationNames" .destinationNames "type" .type "ecosystem" .ecosystem) -}}
{{- else }}
{{ include "pipeline.alloy.stamper.ref" (dict "feature" .featureKey "type" .type "ecosystem" .ecosystem) }},
{{- end -}}
{{- end }}

{{/* Convenience wrapper used by feature templates. Renders the chart-owned boundary
     components (stamper, processor config slices, output sinks, destination gates) for a
     feature's (type, ecosystem). No-op when the feature has no applicable processors.

     Inputs: root (.), featureKey (string), destinationNames ([]string), type, ecosystem. */}}
{{- define "pipeline.alloy.feature.render.forFeature" -}}
{{- $dp := default dict .root.Values.dataProcessors -}}
{{- $chosenDataProcessors := dig "dataProcessors" list (default dict (get .root.Values .featureKey)) }}
{{- $chain := include "dataProcessors.get" (dict "dataProcessors" $dp "chosen" $chosenDataProcessors "type" .type "ecosystem" .ecosystem) | fromYamlArray -}}
{{- include "pipeline.alloy.feature.render" (dict "destinations" .root.Values.destinations "destinationNames" .destinationNames "dataProcessors" $dp "processorNames" $chain "feature" .featureKey "type" .type "ecosystem" .ecosystem) -}}
{{- end }}

{{/* Stable Alloy component reference for a feature's selected_destinations stamper.
     Used by both pipeline.alloy.targets.forFeature (to emit the ref) and the orchestrator (to render
     the component under that exact name). Component type is chosen per ecosystem so it can
     attach the routing label/attribute in the data's native form.

     Inputs: feature (string), type (string), ecosystem (string). */}}
{{- define "pipeline.alloy.stamper.ref" -}}
{{- $name := printf "%s_stamp_%s_%s" (include "helper.alloy_name" .feature) .type .ecosystem -}}
{{- if eq .ecosystem "prometheus" -}}prometheus.relabel.{{ $name }}.receiver
{{- else if eq .ecosystem "loki" -}}loki.process.{{ $name }}.receiver
{{- else if eq .ecosystem "otlp" -}}otelcol.processor.transform.{{ $name }}.input
{{- else if eq .ecosystem "pyroscope" -}}pyroscope.relabel.{{ $name }}.receiver
{{- end -}}
{{- end }}

{{/* Maps a telemetry type to the OTTL statements block name used by otelcol.processor.transform.
     Inputs: type (string). */}}
{{- define "pipeline.alloy.otlp.statementsBlock" -}}
{{- if eq . "metrics" -}}metric_statements
{{- else if eq . "logs" -}}log_statements
{{- else if eq . "traces" -}}trace_statements
{{- end -}}
{{- end }}

{{/* Renders the per-(feature, type, ecosystem) selected_destinations stamper. The stamper
     receives data from the feature's module, attaches a `selected_destinations` label/attribute
     listing the destinations the feature would have selected on its own, and forwards into
     the first processor in the chain.

     Component type per ecosystem mirrors pipeline.alloy.stamper.ref so the ref and the rendered
     component always match.

     Inputs:
       feature (string)            — feature key
       type (string)               — metrics | logs | traces | profiles
       ecosystem (string)          — prometheus | otlp | loki | pyroscope
       destinationNames ([]string) — destinations to stamp into selected_destinations
       nextInput (string)          — Alloy ref of the first processor in the chain */}}
{{- define "pipeline.alloy.stamper.render" }}
{{- $name := printf "%s_stamp_%s_%s" (include "helper.alloy_name" .feature) .type .ecosystem -}}
{{- $destList := join "," .destinationNames }}
{{- if eq .ecosystem "prometheus" }}
prometheus.relabel {{ $name | quote }} {
  forward_to = [{{ .nextInput }}]
  rule {
    target_label = "selected_destinations"
    replacement  = {{ $destList | quote }}
  }
}
{{- else if eq .ecosystem "loki" }}
loki.process {{ $name | quote }} {
  forward_to = [{{ .nextInput }}]
  stage.static_labels {
    values = {
      selected_destinations = {{ $destList | quote }},
    }
  }
}
{{- else if eq .ecosystem "otlp" }}
{{- $block := include "pipeline.alloy.otlp.statementsBlock" .type }}
otelcol.processor.transform {{ $name | quote }} {
  error_mode = "ignore"
  {{ $block }} {
    context = "resource"
    statements = [
      {{ printf `set(attributes["selected_destinations"], "%s")` $destList | quote }},
    ]
  }
  output {
    {{ .type }} = [{{ .nextInput }}]
  }
}
{{- else if eq .ecosystem "pyroscope" }}
pyroscope.relabel {{ $name | quote }} {
  forward_to = [{{ .nextInput }}]
  rule {
    target_label = "selected_destinations"
    replacement  = {{ $destList | quote }}
  }
}
{{- end }}
{{- end }}

{{/* Stable Alloy component reference for a processor's output sink (one per (processor,
     type, ecosystem)). The user's `config` block references this name as its terminal
     forward_to. The chart wires the sink's downstream forward_to to either the next
     processor's input or to per-destination gates.

     Inputs: processor (string), type (string), ecosystem (string). */}}
{{- define "pipeline.alloy.outputSink.ref" -}}
{{- $name := printf "%s_out_%s_%s" (include "helper.alloy_name" .processor) .type .ecosystem -}}
{{- if eq .ecosystem "prometheus" -}}prometheus.relabel.{{ $name }}.receiver
{{- else if eq .ecosystem "loki" -}}loki.process.{{ $name }}.receiver
{{- else if eq .ecosystem "otlp" -}}otelcol.processor.batch.{{ $name }}.input
{{- else if eq .ecosystem "pyroscope" -}}pyroscope.relabel.{{ $name }}.receiver
{{- end -}}
{{- end }}

{{/* Renders the per-(processor, type, ecosystem) output sink component. Passthrough that
     forwards to either the next processor's input (intermediate) or to per-destination
     gate receivers (terminal). Component type per ecosystem mirrors outputSink.ref so
     the ref the user writes and the component the chart renders always match.

     Inputs:
       processor (string)
       type (string)
       ecosystem (string)
       nextTargets ([]string) — list of Alloy refs the sink forwards to */}}
{{- define "pipeline.alloy.outputSink.render" }}
{{- $name := printf "%s_out_%s_%s" (include "helper.alloy_name" .processor) .type .ecosystem }}
{{- $targets := join ", " .nextTargets }}
{{- if eq .ecosystem "prometheus" }}
prometheus.relabel {{ $name | quote }} {
  forward_to = [{{ $targets }}]
}
{{- else if eq .ecosystem "loki" }}
loki.process {{ $name | quote }} {
  forward_to = [{{ $targets }}]
}
{{- else if eq .ecosystem "otlp" }}
otelcol.processor.batch {{ $name | quote }} {
  output {
    {{ .type }} = [{{ $targets }}]
  }
}
{{- else if eq .ecosystem "pyroscope" }}
pyroscope.relabel {{ $name | quote }} {
  forward_to = [{{ $targets }}]
}
{{- end }}
{{- end }}

{{/* Stable Alloy component reference for a destination gate. One gate per
     (terminal processor, destination, type, ecosystem) — drops records whose
     `selected_destinations` label/attribute doesn't contain this destination.

     Inputs: processor (string), destination (string), type (string), ecosystem (string). */}}
{{- define "pipeline.alloy.gate.ref" -}}
{{- $name := printf "%s_%s_gate_%s_%s" (include "helper.alloy_name" .processor) (include "helper.alloy_name" .destination) .type .ecosystem -}}
{{- if eq .ecosystem "prometheus" -}}prometheus.relabel.{{ $name }}.receiver
{{- else if eq .ecosystem "loki" -}}loki.relabel.{{ $name }}.receiver
{{- else if eq .ecosystem "otlp" -}}otelcol.processor.filter.{{ $name }}.input
{{- else if eq .ecosystem "pyroscope" -}}pyroscope.relabel.{{ $name }}.receiver
{{- end -}}
{{- end }}

{{/* Renders the per-(processor, destination, type, ecosystem) destination gate. Keeps
     only records whose `selected_destinations` contains this destination name, strips
     the label/attribute, and forwards to the destination's receiver.

     Inputs:
       processor (string)
       destination (string)
       type (string)
       ecosystem (string)
       destinationTarget (string) — final destination component ref */}}
{{- define "pipeline.alloy.gate.render" }}
{{- $name := printf "%s_%s_gate_%s_%s" (include "helper.alloy_name" .processor) (include "helper.alloy_name" .destination) .type .ecosystem }}
{{- $keepRegex := printf "(^|.*,)%s(,.*|$)" .destination }}
{{- if eq .ecosystem "prometheus" }}
prometheus.relabel {{ $name | quote }} {
  forward_to = [{{ .destinationTarget }}]
  rule {
    source_labels = ["selected_destinations"]
    regex         = {{ $keepRegex | quote }}
    action        = "keep"
  }
  rule {
    action = "labeldrop"
    regex  = "selected_destinations"
  }
}
{{- else if eq .ecosystem "loki" }}
loki.relabel {{ $name | quote }} {
  forward_to = [{{ .destinationTarget }}]
  rule {
    source_labels = ["selected_destinations"]
    regex         = {{ $keepRegex | quote }}
    action        = "keep"
  }
  rule {
    action = "labeldrop"
    regex  = "selected_destinations"
  }
  max_cache_size = 100
}
{{- else if eq .ecosystem "otlp" }}
{{- $dropExpr := printf `not IsMatch(resource.attributes["selected_destinations"], "%s")` $keepRegex }}
{{- $block := include "pipeline.alloy.otlp.statementsBlock" .type }}
otelcol.processor.filter {{ $name | quote }} {
  error_mode = "ignore"
  {{ .type }} {
    {{- if eq .type "metrics" }}
    metric = [
      {{ $dropExpr | quote }},
    ]
    {{- else if eq .type "logs" }}
    log_record = [
      {{ $dropExpr | quote }},
    ]
    {{- else if eq .type "traces" }}
    span = [
      {{ $dropExpr | quote }},
    ]
    {{- end }}
  }
  output {
    {{ .type }} = [otelcol.processor.transform.{{ $name }}_strip.input]
  }
}
otelcol.processor.transform "{{ $name }}_strip" {
  error_mode = "ignore"
  {{ $block }} {
    context = "resource"
    statements = [
      "delete_key(attributes, \"selected_destinations\")",
    ]
  }
  output {
    {{ .type }} = [{{ .destinationTarget }}]
  }
}
{{- else if eq .ecosystem "pyroscope" }}
pyroscope.relabel {{ $name | quote }} {
  forward_to = [{{ .destinationTarget }}]
  rule {
    source_labels = ["selected_destinations"]
    regex         = {{ $keepRegex | quote }}
    action        = "keep"
  }
  rule {
    action = "labeldrop"
    regex  = "selected_destinations"
  }
}
{{- end }}
{{- end }}

{{/* Renders, for ONE (feature, type, ecosystem) tuple, all chart-owned boundary components:
     - stamper (forwards from feature module into the chain)
     - each processor's user-config slice for this (type, ecosystem)
     - per-position output sinks (one per processor in the chain)
     - per-destination gates (after the terminal processor)

     Slices are emitted per (feature, type, ecosystem), so a processor used by features on
     different collectors only renders the pipelines each collector actually needs.

     Inputs:
       destinations (map)            — .Values.destinations
       destinationNames ([]string)
       processors (map)              — .Values.dataProcessors
       processorNames ([]string)     — feature's chain, already filtered to those supporting
                                       (type, ecosystem). Empty = no-op.
       feature (string)
       type (string)
       ecosystem (string) */}}
{{- define "pipeline.alloy.feature.render" }}
{{- if not (empty .processorNames) }}
{{- $chain := .processorNames }}
{{- $chainLen := len $chain }}
{{- $firstName := index $chain 0 }}
{{- $firstProc := get .dataProcessors $firstName }}
{{- $firstInput := include (printf "dataProcessors.%s.alloy.%s.%s.input" $firstProc.type .ecosystem .type) (dict "processor" $firstProc "processorName" $firstName) }}
{{- /* 1. Stamper: from feature module into the first processor */}}
{{- include "pipeline.alloy.stamper.render" (dict "feature" .feature "type" .type "ecosystem" .ecosystem "destinationNames" .destinationNames "nextInput" $firstInput) }}

{{- /* 2. For each processor in the chain emit (a) its user-config slice for this
       (type, ecosystem) and (b) the output sink. The sink forwards to the next
       processor's input or (if terminal) to per-destination gate receivers. */}}
{{- range $idx, $procName := $chain }}
  {{- $proc := get $.dataProcessors $procName }}
// Processor: {{ $procName }} ({{ $proc.type }}) — {{ $.type }}/{{ $.ecosystem }}
{{ include (printf "dataProcessors.%s.alloy.%s.%s.config" $proc.type $.ecosystem $.type) (dict "processor" $proc "processorName" $procName) | trim }}

  {{- $nextTargets := list }}
  {{- if lt $idx (sub $chainLen 1) }}
    {{- $nextName := index $chain (add $idx 1) }}
    {{- $nextProc := get $.dataProcessors $nextName }}
    {{- $nextInput := include (printf "dataProcessors.%s.alloy.%s.%s.input" $nextProc.type $.ecosystem $.type) (dict "processor" $nextProc "processorName" $nextName) }}
    {{- $nextTargets = append $nextTargets $nextInput }}
  {{- else }}
    {{- range $destName := $.destinationNames }}
      {{- $gateRef := include "pipeline.alloy.gate.ref" (dict "processor" $procName "destination" $destName "type" $.type "ecosystem" $.ecosystem) }}
      {{- $nextTargets = append $nextTargets $gateRef }}
    {{- end }}
  {{- end }}
  {{- include "pipeline.alloy.outputSink.render" (dict "processor" $procName "type" $.type "ecosystem" $.ecosystem "nextTargets" $nextTargets) }}
{{- end }}

{{- /* 3. Destination gates: one per (terminal processor, destination). */}}
{{- $terminal := index $chain (sub $chainLen 1) }}
{{- range $destName := .destinationNames }}
  {{- if hasKey $.destinations $destName }}
    {{- $destination := get $.destinations $destName }}
    {{- $destTarget := include (printf "destinations.%s.alloy.%s.%s.target" $destination.type $.ecosystem $.type) (dict "destination" $destination "destinationName" $destName) | trim }}
    {{- include "pipeline.alloy.gate.render" (dict "processor" $terminal "destination" $destName "type" $.type "ecosystem" $.ecosystem "destinationTarget" $destTarget) }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
