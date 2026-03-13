{{/* Does some basic destination validation */}}
{{/* Inputs: . (Values) */}}
{{- define "destinations.validate" }}
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
