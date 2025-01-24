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

    {{/* Check if OTLP destination using Grafana Cloud has protocol set */}}
    {{- if and (eq $destination.type "otlp") ($destination.url) (contains ".grafana.net" $destination.url) }}
      {{- if ne $destination.protocol "http" }}
        {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud OTLP gateway but has incorrect protocol '%s', the gateway only supports 'http'.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    protocol: http" $i $destination.name ($destination.protocol | default "grpc (default)") $destination.name $destination.url) }}
      {{- end }}
    {{- end }}

    {{- if eq (include "secrets.authType" $destination) "basic" }}
      {{- if eq (include "secrets.usesSecret" (dict "object" $destination "key" "auth.username")) "false" }}
        {{ fail (printf "\nDestination #%d (%s) is using basic auth but does not have a username.\nPlease set:\ndestinations:\n  - name: %s\n    auth:\n      type: basic\n      username: my-username\n      password: my-password" $i $destination.name $destination.name) }}
      {{- end }}
      {{- if eq (include "secrets.usesSecret" (dict "object" $destination "key" "auth.password")) "false" }}
        {{ fail (printf "\nDestination #%d (%s) is using basic auth but does not have a password.\nPlease set:\ndestinations:\n  - name: %s\n    auth:\n      type: basic\n      username: my-username\n      password: my-password" $i $destination.name $destination.name) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
