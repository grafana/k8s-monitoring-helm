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
{{- define "dataProcessors.pipeline.targets.forFeature" -}}
{{- $root := .root -}}
{{- $featureKey := .featureKey -}}
{{- $destinationNames := .destinationNames -}}
{{- $type := .type -}}
{{- $ecosystem := .ecosystem -}}
{{- $dp := default dict $root.Values.dataProcessors -}}
{{- $chosenDataProcessors := dig "dataProcessors" list (default dict (get $root.Values $featureKey)) }}
{{- /* Resolve the chain for THIS (type, ecosystem). Only route through a stamper when at
       least one chosen processor actually supports this tuple; otherwise the stamper ref
       would be emitted here but never rendered by dataProcessors.pipeline.render.forFeature (which branches
       on the same resolved chain), leaving a dangling Alloy reference. */}}
{{- $chain := include "dataProcessors.get" (dict "dataProcessors" $dp "chosen" $chosenDataProcessors "type" $type "ecosystem" $ecosystem) | fromYamlArray -}}
{{- /* Precise router-capability check (replaces the old router-side R10 inference, see
       destinations.router.assertCanCarry in destinations/_destination_router_validations.tpl for
       the full rationale): this define is called once per (feature, type, ecosystem) tuple the
       feature actually emits, with destinationNames already resolved for that tuple, so it is
       the only seam where "the feature really sends `.type`" and "this router can carry `.type`"
       can both be known at once. Guarded on type == router so non-router configs never even
       enter the check -- zero-cost, zero-diff for the overwhelmingly common case. */}}
{{- range $destName := $destinationNames }}
  {{- if and (hasKey $root.Values.destinations $destName) (eq (get $root.Values.destinations $destName).type "router") }}
    {{- include "destinations.router.assertCanCarry" (dict "root" $root "featureKey" $featureKey "routerName" $destName "type" $type "ecosystem" $ecosystem) }}
  {{- end }}
{{- end -}}
{{- if empty $chain -}}
{{- include "destinations.alloy.targets" (dict "destinations" $root.Values.destinations "destinationNames" $destinationNames "type" $type "ecosystem" $ecosystem) -}}
{{- else }}
{{ include "dataProcessors.pipeline.stamper.ref" (dict "feature" $featureKey "type" $type "ecosystem" $ecosystem) }},
{{- end -}}
{{- end }}

{{/* Convenience wrapper used by feature templates. Emits the feature's per-feature stamper (which
     the feature's module forwards into) and records the feature's resolved processor chain into a
     per-collector accumulator. The shared chain body (processor config slices, output sinks,
     destination gates) is NOT rendered here — it is rendered exactly once per collector by
     dataProcessors.pipeline.collectorChains.flush. No-op when the feature has no applicable processors.

     Recording the chain instead of rendering its body here is what prevents duplicate block
     declarations when two features on the same collector share a processor: the slice/sink/gate
     component names are keyed by (processor, type, ecosystem), not by feature, so rendering them
     once per feature would collide (issue #3014).

     Inputs: root (.), featureKey (string), destinationNames ([]string), type, ecosystem. */}}
{{- define "dataProcessors.pipeline.render.forFeature" -}}
{{- $dp := default dict .root.Values.dataProcessors -}}
{{- $chosenDataProcessors := dig "dataProcessors" list (default dict (get .root.Values .featureKey)) }}
{{- $chain := include "dataProcessors.get" (dict "dataProcessors" $dp "chosen" $chosenDataProcessors "type" .type "ecosystem" .ecosystem) | fromYamlArray -}}
{{- if not (empty $chain) -}}
{{- /* Per-feature stamper: emitted inline so each feature's module forwards into its own stamper,
       which stamps that feature's selected_destinations and forwards into the shared chain. */}}
{{- include "dataProcessors.pipeline.stamper.forFeature" (dict "destinationNames" .destinationNames "dataProcessors" $dp "processorNames" $chain "feature" .featureKey "type" .type "ecosystem" .ecosystem) -}}
{{- /* Record the chain for once-per-collector rendering, unioning destinations across the features
       on this collector that use it. */}}
{{- include "dataProcessors.pipeline.collectorChains.record" (dict "root" .root "collectorName" .root.collectorName "featureKey" .featureKey "destinationNames" .destinationNames "processorNames" $chain "type" .type "ecosystem" .ecosystem) -}}
{{- end -}}
{{- end }}

{{/* Records a feature's resolved chain into the per-collector accumulator stashed on .Values. Entries
     are keyed by (collector, chain, type, ecosystem); destinationNames are unioned across every
     feature that resolves the same key so the single shared chain body carries a gate for each
     destination any contributing feature selected. Populated by dataProcessors.pipeline.render.forFeature
     as the orchestrator walks the features of a collector; drained by dataProcessors.pipeline.collectorChains.flush.

     A processor's slice/sink components are keyed by (processor, type, ecosystem), so a processor
     can only be shared across features on a collector when they resolve the SAME chain — otherwise
     its single set of components would need two different wirings. Such a conflict is detected here
     and fails with an actionable message rather than emitting a config Alloy rejects as
     "block ... already declared".

     Inputs: root (.), collectorName, featureKey, destinationNames ([]string), processorNames ([]string), type, ecosystem. */}}
{{- define "dataProcessors.pipeline.collectorChains.record" -}}
{{- $acc := .root.Values.__dataProcessorChains -}}
{{- if not $acc -}}
{{- $acc = dict -}}
{{- $_ := set .root.Values "__dataProcessorChains" $acc -}}
{{- end -}}
{{- $chainStr := join "|" .processorNames -}}
{{- $key := printf "%s:::%s:::%s:::%s" .collectorName $chainStr .type .ecosystem -}}
{{- /* Conflict guard: the same processor may not appear in two different chains on one collector
       (same type/ecosystem), since its shared components can't carry two wirings. */}}
{{- $owners := .root.Values.__dataProcessorChainOwners -}}
{{- if not $owners -}}
{{- $owners = dict -}}
{{- $_ := set .root.Values "__dataProcessorChainOwners" $owners -}}
{{- end -}}
{{- range $procName := .processorNames -}}
{{- $ownerKey := printf "%s:::%s:::%s:::%s" $.collectorName $procName $.type $.ecosystem -}}
{{- if hasKey $owners $ownerKey -}}
{{- $owner := get $owners $ownerKey -}}
{{- if ne $owner.chain $chainStr -}}
{{- $msg := list "" (printf "The data processor %q is used in two different processor chains on collector %q:" $procName $.collectorName) -}}
{{- $msg = append $msg (printf "  - feature %q uses chain [%s]" $owner.feature (join ", " (splitList "|" $owner.chain))) -}}
{{- $msg = append $msg (printf "  - feature %q uses chain [%s]" $.featureKey (join ", " $.processorNames)) -}}
{{- $msg = append $msg "A processor's components are shared per collector, so features that share a processor must use the same chain." -}}
{{- $msg = append $msg "Give these features identical dataProcessors lists, or define separate processors for each." -}}
{{- fail (join "\n" $msg) -}}
{{- end -}}
{{- else -}}
{{- $_ := set $owners $ownerKey (dict "chain" $chainStr "feature" $.featureKey) -}}
{{- end -}}
{{- end -}}
{{- if hasKey $acc $key -}}
{{- $entry := get $acc $key -}}
{{- $_ := set $entry "destinationNames" (concat $entry.destinationNames .destinationNames | uniq) -}}
{{- else -}}
{{- $_ := set $acc $key (dict "collectorName" .collectorName "processorNames" .processorNames "type" .type "ecosystem" .ecosystem "destinationNames" (.destinationNames | uniq)) -}}
{{- end -}}
{{- end }}

{{/* Renders every chain body accumulated for a collector, exactly once each. Called once per collector
     by the orchestrator after the feature modules are assembled and BEFORE
     dataProcessors.alloy.collectorComponents (which gates shared discovery on the config already
     referencing it, so the chain body slices must exist by then). Entries are matched by collectorName
     and emitted in a stable key order for deterministic output.

     Inputs: root (.), collectorName. */}}
{{- define "dataProcessors.pipeline.collectorChains.flush" -}}
{{- $acc := default dict .root.Values.__dataProcessorChains -}}
{{- range $key := (keys $acc | sortAlpha) }}
{{- $entry := get $acc $key }}
{{- if eq $entry.collectorName $.collectorName }}
{{- include "dataProcessors.pipeline.chain.render" (dict "destinations" $.root.Values.destinations "destinationNames" ($entry.destinationNames | uniq | sortAlpha) "dataProcessors" $.root.Values.dataProcessors "processorNames" $entry.processorNames "type" $entry.type "ecosystem" $entry.ecosystem) }}
{{- end }}
{{- end }}
{{- end }}

{{/* Stable Alloy component reference for a feature's selected_destinations stamper.
     Used by both dataProcessors.pipeline.targets.forFeature (to emit the ref) and the orchestrator (to render
     the component under that exact name). Component type is chosen per ecosystem so it can
     attach the routing label/attribute in the data's native form.

     Inputs: feature (string), type (string), ecosystem (string). */}}
{{- define "dataProcessors.pipeline.stamper.ref" -}}
{{- $name := printf "%s_stamp_%s_%s" (include "helper.alloy_name" .feature) .type .ecosystem -}}
{{- if eq .ecosystem "prometheus" -}}prometheus.relabel.{{ $name }}.receiver
{{- else if eq .ecosystem "loki" -}}loki.process.{{ $name }}.receiver
{{- else if eq .ecosystem "otlp" -}}otelcol.processor.transform.{{ $name }}.input
{{- else if eq .ecosystem "pyroscope" -}}pyroscope.relabel.{{ $name }}.receiver
{{- end -}}
{{- end }}

{{/* Maps a telemetry type to the OTTL statements block name used by otelcol.processor.transform.
     Inputs: type (string). */}}
{{- define "dataProcessors.pipeline.otlp.statementsBlock" -}}
{{- if eq . "metrics" -}}metric_statements
{{- else if eq . "logs" -}}log_statements
{{- else if eq . "traces" -}}trace_statements
{{- end -}}
{{- end }}

{{/* Renders the per-(feature, type, ecosystem) selected_destinations stamper. The stamper
     receives data from the feature's module, attaches a `selected_destinations` label/attribute
     listing the destinations the feature would have selected on its own, and forwards into
     the first processor in the chain.

     Component type per ecosystem mirrors dataProcessors.pipeline.stamper.ref so the ref and the rendered
     component always match.

     Inputs:
       feature (string)            — feature key
       type (string)               — metrics | logs | traces | profiles
       ecosystem (string)          — prometheus | otlp | loki | pyroscope
       destinationNames ([]string) — destinations to stamp into selected_destinations
       nextInput (string)          — Alloy ref of the first processor in the chain */}}
{{- define "dataProcessors.pipeline.stamper.render" }}
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
{{- $block := include "dataProcessors.pipeline.otlp.statementsBlock" .type }}
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
{{- define "dataProcessors.pipeline.outputSink.ref" -}}
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
{{- define "dataProcessors.pipeline.outputSink.render" }}
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
{{- define "dataProcessors.pipeline.gate.ref" -}}
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
{{- define "dataProcessors.pipeline.gate.render" }}
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
{{- $dropExpr := printf `not IsMatch(attributes["selected_destinations"], "%s")` $keepRegex }}
{{- $block := include "dataProcessors.pipeline.otlp.statementsBlock" .type }}
otelcol.processor.filter {{ $name | quote }} {
  error_mode = "ignore"
  {{- if eq .type "metrics" }}
  metric_conditions {
    context    = "resource"
    conditions = [
      {{ $dropExpr | quote }},
    ]
  }
  {{- else if eq .type "logs" }}
  log_conditions {
    context    = "resource"
    conditions = [
      {{ $dropExpr | quote }},
    ]
  }
  {{- else if eq .type "traces" }}
  trace_conditions {
    context    = "resource"
    conditions = [
      {{ $dropExpr | quote }},
    ]
  }
  {{- end }}
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

{{/* Renders ONLY the per-feature stamper: the feature's module forwards into this component, which
     stamps the feature's selected_destinations and forwards into the first processor of the shared
     chain. Kept per-feature (its name is keyed by feature); the chain body it feeds is shared once
     per collector by dataProcessors.pipeline.chain.render.

     Inputs:
       destinationNames ([]string)
       dataProcessors (map)          — .Values.dataProcessors
       processorNames ([]string)     — feature's chain, already filtered to those supporting
                                       (type, ecosystem). Must be non-empty.
       feature (string)
       type (string)
       ecosystem (string) */}}
{{- define "dataProcessors.pipeline.stamper.forFeature" }}
{{- $chain := .processorNames }}
{{- $firstName := index $chain 0 }}
{{- $firstProc := get .dataProcessors $firstName }}
{{- $firstInput := include (printf "dataProcessors.%s.alloy.%s.%s.input" $firstProc.type .ecosystem .type) (dict "processor" $firstProc "processorName" $firstName) }}
{{- include "dataProcessors.pipeline.stamper.render" (dict "feature" .feature "type" .type "ecosystem" .ecosystem "destinationNames" .destinationNames "nextInput" $firstInput) }}
{{- end }}

{{/* Renders, for ONE (chain, type, ecosystem) on a collector, the shared chart-owned components:
     - each processor's user-config slice for this (type, ecosystem)
     - per-position output sinks (one per processor in the chain)
     - per-destination gates (after the terminal processor)

     None of these are keyed by feature, so this body is rendered exactly once per collector per
     unique chain (see dataProcessors.pipeline.collectorChains.flush) with the UNION of destinations across
     the features that use the chain. The per-feature stampers (dataProcessors.pipeline.stamper.forFeature)
     forward into the first processor's input, so multiple features share this single body.

     Inputs:
       destinations (map)            — .Values.destinations
       destinationNames ([]string)   — union across features using this chain on the collector
       dataProcessors (map)          — .Values.dataProcessors
       processorNames ([]string)     — chain, already filtered to those supporting (type, ecosystem).
                                       Empty = no-op.
       type (string)
       ecosystem (string) */}}
{{- define "dataProcessors.pipeline.chain.render" }}
{{- if not (empty .processorNames) }}
{{- $chain := .processorNames }}
{{- $chainLen := len $chain }}
{{- /* For each processor in the chain emit (a) its user-config slice for this
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
      {{- $gateRef := include "dataProcessors.pipeline.gate.ref" (dict "processor" $procName "destination" $destName "type" $.type "ecosystem" $.ecosystem) }}
      {{- $nextTargets = append $nextTargets $gateRef }}
    {{- end }}
  {{- end }}
  {{- include "dataProcessors.pipeline.outputSink.render" (dict "processor" $procName "type" $.type "ecosystem" $.ecosystem "nextTargets" $nextTargets) }}
{{- end }}

{{- /* 3. Destination gates: one per (terminal processor, destination). */}}
{{- $terminal := index $chain (sub $chainLen 1) }}
{{- range $destName := .destinationNames }}
  {{- if hasKey $.destinations $destName }}
    {{- $destination := get $.destinations $destName }}
    {{- $destTarget := include (printf "destinations.%s.alloy.%s.%s.target" $destination.type $.ecosystem $.type) (dict "destination" $destination "destinationName" $destName) | trim }}
    {{- include "dataProcessors.pipeline.gate.render" (dict "processor" $terminal "destination" $destName "type" $.type "ecosystem" $.ecosystem "destinationTarget" $destTarget) }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
