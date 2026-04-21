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

{{/* Inputs: destinations (array of destination names), type (string), featureName (string) */}}
{{- define "destinations.validate.destinationListNotEmpty" }}
{{- if empty .destinations }}
  {{- $msg := list "" (printf "No destinations found that can accept %s from the %s feature." .type .featureName) }}
  {{- $msg = append $msg (printf "Please add a destination with %s support." .type) }}
  {{- $msg = append $msg "See https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/destinations/README.md for more details." }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Does some basic destination validation */}}
{{/* Inputs: . (Values) */}}
{{- define "destinations.validate" }}
  {{- include "destinations.validate.uniqueNames" . }}
  {{- range $destinationName , $destination := .Values.destinations }}
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
  {{- end }}
{{- end }}
