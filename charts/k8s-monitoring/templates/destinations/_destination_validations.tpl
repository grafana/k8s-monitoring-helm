{{/* Does some basic destination validation */}}
{{/* Inputs: . (Values) */}}
{{- define "destinations.validate" }}
  {{- range $i, $destination := .Values.destinations }}
    {{- if not $destination.name }}
      {{- $msg := list "" (printf "Destination #%d does not have a name." $i) }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "destinations:" }}
      {{- $msg = append $msg "  - name: my-destination-name" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- if (regexFind "[^-_ a-zA-Z0-9]" $destination.name) }}
      {{- $msg := list "" (printf "Destination #%d (%s) invalid characters in its name." $i $destination.name) }}
      {{- $msg = append $msg "Please only use alphanumeric, underscores, dashes, or spaces." }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- $types := (include "destinations.types" . ) | fromYamlArray }}
    {{- if not $destination.type }}
      {{ fail (printf "\nDestination #%d (%s) does not have a type.\nPlease set:\ndestinations:\n  - name: %s\n    type: %s" $i $destination.name $destination.name (include "english_list_or" $types)) }}
    {{- end }}

    {{- if not (has $destination.type $types) }}
      {{ fail (printf "\nDestination #%d (%s) is using an unknown type (%s).\nPlease set:\ndestinations:\n  - name: %s\n    type: %s" $i $destination.name $destination.type $destination.name (include "english_list_or" $types)) }}
    {{- end }}

    {{- if eq (include "secrets.authType" $destination) "basic" }}
      {{- if eq (include "secrets.usesSecret" (dict "object" $destination "key" "auth.username")) "false" }}
        {{ fail (printf "\nDestination #%d (%s) is using basic auth but does not have a username.\nPlease set:\ndestinations:\n  - name: %s\n    auth:\n      type: basic\n      username: my-username\n      password: my-password" $i $destination.name $destination.name) }}
      {{- end }}
      {{- if eq (include "secrets.usesSecret" (dict "object" $destination "key" "auth.password")) "false" }}
        {{ fail (printf "\nDestination #%d (%s) is using basic auth but does not have a password.\nPlease set:\ndestinations:\n  - name: %s\n    auth:\n      type: basic\n      username: my-username\n      password: my-password" $i $destination.name $destination.name) }}
      {{- end }}
    {{- end }}

    {{/* OTLP destination validations */}}
    {{- if (eq $destination.type "otlp") }}
      {{- include "destinations.otlp.validate" (dict "Values" . "Destination" $destination "DestinationIndex" $i) -}}
    {{- end }}
  {{- end }}
{{- end }}
