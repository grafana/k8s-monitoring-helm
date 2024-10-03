{{/* Does some basic destination validation */}}
{{/* Inputs: . (Values) */}}
{{- define "destinations.validate" }}
  {{- range $i, $destination := .Values.destinations }}
    {{- if not $destination.name }}
      {{ fail (printf "\nDestination #%d does not have a name.\nPlease set:\ndestinations:\n  - name: my-destination-name" $i) }}
    {{- end }}

    {{- $types := (include "destinations.types" . ) | fromYamlArray }}
    {{- if not $destination.type }}
      {{ fail (printf "\nDestination \"%s\" does not have a type.\nPlease set:\ndestinations:\n  - name: %s\n    type: %s" $destination.name $destination.name ($types | join "|")) }}
    {{- end }}

    {{- if not (has $destination.type $types) }}
      {{ fail (printf "\nDestination \"%s\" is using an unknown type (%s).\nPlease set:\ndestinations:\n  - name: %s\n    type: \"[%s]\"" $destination.name $destination.type $destination.name ($types | join "|")) }}
    {{- end }}
  {{- end }}
{{- end }}

