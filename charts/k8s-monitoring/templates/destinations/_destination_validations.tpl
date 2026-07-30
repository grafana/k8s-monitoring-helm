{{/* Fails if two destination keys normalize to the same Kubernetes-safe name (e.g. myDest and mydest, or my_dest and my-dest). */}}
{{- define "destinations.validate.uniqueNames" }}
  {{- $byNormalized := dict }}
  {{- range $destinationName := keys (.Values.destinations | default dict) | sortAlpha }}
    {{- $normalized := include "helper.kubernetesName" $destinationName | trim }}
    {{- $existing := index $byNormalized $normalized | default list }}
    {{- $_ := set $byNormalized $normalized (append $existing $destinationName) }}
  {{- end }}
  {{- range $normalized, $destinationNames := $byNormalized }}
    {{- if gt (len $destinationNames) 1 }}
      {{- $msg := list "" (printf "Multiple destinations resolve to the same Kubernetes resource name %q: %s" $normalized (join ", " $destinationNames)) }}
      {{- $msg = append $msg "Destination names are normalized to lowercase DNS-1123 names when used as Kubernetes resource names, so they must be unique after normalization." }}
      {{- $msg = append $msg "Please rename all but one of these destinations." }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* Inputs: destinations (array of destination names), type (string), featureName (string),
     Values (optional, the chart's .Values), featureKey (optional, this feature's values key).

     When Values and featureKey are supplied and the empty list was caused by router shadowing --
     every destination that could have carried this signal sits behind a router, and routers are
     excluded from implicit selection (see the F7 comment on destinations.get) -- say so and
     suggest naming the router, instead of the default "add a destination" advice. Without that
     branch the message tells the user to add a destination of a type they already have, which is
     the one situation where the generic advice is actively wrong. */}}
{{- define "destinations.validate.destinationListNotEmpty" }}
{{- if empty .destinations }}
  {{- $routerCandidates := list }}
  {{- $shadowedButCapable := list }}
  {{- if and .Values .featureKey }}
    {{- /* Shadowing only suppresses IMPLICIT selection. When the feature sets its own
           `destinations` filter, destinations.get honours that filter verbatim and never consults
           the shadow set (see the explicit-filter branch of destinations.get), so an empty result
           means the filter itself is wrong -- a typo, or a destination that does not carry this
           signal. Blaming a router there would tell the user to overwrite a choice they made
           deliberately, so fall through to the generic advice. */}}
    {{- $featureValues := index $.Values .featureKey | default dict }}
    {{- $filter := $featureValues.destinations | default list }}
    {{- if empty $filter }}
      {{- $enabledDestinations := include "destinations.getEnabled" ($.Values.destinations | default dict) | fromYaml }}
      {{- /* Real destinations that carry this signal. Routers are excluded: their supports_<signal>
             is unconditionally true, so counting them would treat a router as its own downstream.
             Capability is checked against the raw destination values, matching how
             destinations.get decides what it would have selected. */}}
      {{- $capable := dict }}
      {{- range $destinationName, $destination := $enabledDestinations }}
        {{- if ne $destination.type "router" }}
          {{- if eq (include (printf "destinations.%s.supports_%s" $destination.type $.type) $destination) "true" }}
            {{- $_ := set $capable $destinationName true }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- /* Keep each router paired with the capable destinations IT shadows. Merging every
             router's downstreams into one set would let us suggest a router whose downstreams
             cannot carry this signal at all -- which passes validation and then silently
             misroutes, because destinations.router.supports_<signal> always reports true. */}}
      {{- $reachable := dict }}
      {{- range $routerName, $router := $enabledDestinations }}
        {{- if eq $router.type "router" }}
          {{- $downstream := $router.defaultDestinations | default list }}
          {{- range $route := ($router.routes | default list) }}
            {{- $downstream = concat $downstream ($route.destinations | default list) }}
          {{- end }}
          {{- $matched := false }}
          {{- range $d := $downstream }}
            {{- if hasKey $capable $d }}
              {{- $_ := set $reachable $d true }}
              {{- $matched = true }}
            {{- end }}
          {{- end }}
          {{- if $matched }}
            {{- $routerCandidates = append $routerCandidates $routerName }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- $shadowedButCapable = keys $reachable | sortAlpha }}
      {{- $routerCandidates = $routerCandidates | sortAlpha }}
    {{- end }}
  {{- end }}
  {{- $msg := list "" (printf "No destinations found that can accept %s from the %s feature." .type .featureName) }}
  {{- if and $routerCandidates $shadowedButCapable }}
    {{- $msg = append $msg (printf "These destinations support %s, but are only reachable through a router: %s." .type (join ", " $shadowedButCapable)) }}
    {{- $msg = append $msg (printf "Routers are excluded from implicit destination selection, so this feature must name the router it should send through: %s." (join ", " $routerCandidates)) }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg (printf "%s:" .featureKey) }}
    {{- $msg = append $msg "  destinations:" }}
    {{- $msg = append $msg (printf "    - %s" (first $routerCandidates)) }}
    {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/DestinationRouting.md for more details." }}
  {{- else }}
    {{- $msg = append $msg (printf "Please add a destination with %s support." .type) }}
    {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/destinations/README.md for more details." }}
  {{- end }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Does some basic destination validation */}}
{{/* Inputs: . (Values) */}}
{{- define "destinations.validate" }}
  {{- include "destinations.validate.uniqueNames" . }}
  {{- /* Disabled destinations are excluded from all telemetry data flows, so skip their validation. */}}
  {{- range $destinationName , $destination := (include "destinations.getEnabled" .Values.destinations | fromYaml) }}
    {{- if (regexFind "[^-_a-zA-Z0-9]" $destinationName) }}
      {{- $msg := list "" (printf "Destination \"%s\" has invalid characters in its name." $destinationName) }}
      {{- $msg = append $msg "Please only use alphanumeric, underscores, or dashes." }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- $types := (include "destinations.types" . ) | fromYamlArray }}
    {{- if not $destination.type }}
      {{- $msg := list "" (printf "Destination \"%s\" does not have a type." $destinationName) }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "destinations:" }}
      {{- $msg = append $msg (printf "  %s:" $destinationName) }}
      {{- $msg = append $msg (printf "    type: %s" (include "english_list_or" $types)) }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- if not (has $destination.type $types) }}
      {{- $msg := list "" (printf "Destination \"%s\" is using an unknown type: %s" $destinationName $destination.type) }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "destinations:" }}
      {{- $msg = append $msg (printf "  %s:" $destinationName) }}
      {{- $msg = append $msg (printf "    type: %s" (include "english_list_or" $types)) }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- if eq (include "secrets.authType" $destination) "basic" }}
      {{- if eq (include "secrets.usesSecret" (dict "object" $destination "key" "auth.username")) "false" }}
        {{- $msg := list "" (printf "Destination \"%s\" is using basic auth but does not have a username." $destinationName) }}
        {{- $msg = append $msg "Please set:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  %s:" $destinationName) }}
        {{- $msg = append $msg (printf "    type: %s" $destination.type) }}
        {{- $msg = append $msg "    auth:" }}
        {{- $msg = append $msg "      type: basic" }}
        {{- $msg = append $msg "      username: my-username" }}
        {{- $msg = append $msg "      password: my-password" }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
      {{- if eq (include "secrets.usesSecret" (dict "object" $destination "key" "auth.password")) "false" }}
        {{- $msg := list "" (printf "Destination \"%s\" is using basic auth but does not have a password." $destinationName) }}
        {{- $msg = append $msg "Please set:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  %s:" $destinationName) }}
        {{- $msg = append $msg (printf "    type: %s" $destination.type) }}
        {{- $msg = append $msg "    auth:" }}
        {{- $msg = append $msg "      type: basic" }}
        {{- $msg = append $msg "      username: my-username" }}
        {{- $msg = append $msg "      password: my-password" }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
    {{- end }}

    {{/* OTLP destination validations */}}
    {{- if (eq $destination.type "otlp") }}
      {{- include "destinations.otlp.validate" (dict "Values" . "Destination" $destination "DestinationName" $destinationName) -}}
    {{- end }}

    {{/* Router destination validations. Note: $ (not .) is used here to reach the root context --
         "." has been rebound by the enclosing range to the current $destination, so only $ still
         points at what destinations.validate itself was called with. Router validation needs the
         full destinations map (unlike otlp validation, which only looks at its own Destination),
         so this distinction matters here. */}}
    {{- if (eq $destination.type "router") }}
      {{- include "destinations.router.validate" (dict "Values" $ "Destination" $destination "DestinationName" $destinationName) -}}
    {{- end }}

    {{/* Validate the rules.collector reference for destinations that opt into rule sync. */}}
    {{- if and (dig "rules" "enabled" false $destination) (dig "rules" "collector" "" $destination) }}
      {{- $rulesCollector := $destination.rules.collector }}
      {{- $enabledCollectors := include "collectors.list.enabled" $ | fromYamlArray }}
      {{- if not (has $rulesCollector $enabledCollectors) }}
        {{- $msg := list "" (printf "Destination \"%s\" has rules.enabled=true, but rules.collector \"%s\" is not an enabled collector." $destinationName $rulesCollector) }}
        {{- $msg = append $msg "Set rules.collector to one of the enabled collectors:" }}
        {{- range $c := $enabledCollectors }}{{- $msg = append $msg (printf "  %s" $c) }}{{- end }}
        {{- $msg = append $msg "or leave rules.collector unset to use the first enabled collector." }}
        {{- fail (join "\n" $msg) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
