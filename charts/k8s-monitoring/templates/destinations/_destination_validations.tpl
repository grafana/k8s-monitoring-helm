{{/* Does some basic destination validation */}}
{{/* Inputs: . (Values) */}}
{{- define "destinations.validate" }}
  {{- range $i, $destination := .Values.destinations }}
    {{- if not $destination.name }}
      {{ fail (printf "\nDestination #%d does not have a name.\nPlease set:\ndestinations:\n  - name: my-destination-name" $i) }}
    {{- end }}

    {{- if (regexFind "[^-_ a-zA-Z0-9]" $destination.name) }}
      {{ fail (printf "\nDestination #%d (%s) has invalid characters in its name.\nPlease only use alphanumeric, underscores, dashes, or spaces" $i $destination.name) }}
    {{- end }}

    {{- $types := (include "destinations.types" . ) | fromYamlArray }}
    {{- if not $destination.type }}
      {{ fail (printf "\nDestination #%d (%s) does not have a type.\nPlease set:\ndestinations:\n  - name: %s\n    type: %s" $i $destination.name $destination.name (include "english_list_or" $types)) }}
    {{- end }}

    {{- if not (has $destination.type $types) }}
      {{ fail (printf "\nDestination #%d (%s) is using an unknown type (%s).\nPlease set:\ndestinations:\n  - name: %s\n    type: \"[%s]\"" $i $destination.name $destination.type $destination.name (include "english_list_or" $types)) }}
    {{- end }}
  {{- end }}
{{- end }}
