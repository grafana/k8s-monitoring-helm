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
      {{ fail (printf "\nDestination #%d (%s) is using an unknown type (%s).\nPlease set:\ndestinations:\n  - name: %s\n    type: \"[%s]\"" $i $destination.name $destination.type $destination.name (include "english_list_or" $types)) }}
    {{- end }}

    {{/* OTLP destination validations */}}
    {{- if (eq $destination.type "otlp") }}
      {{/* Check if OTLP destination has a valid protocol set */}}
      {{- if (not (has ($destination.protocol | default "grpc") (list "grpc" "http"))) }}
        {{- $msg := list "" (printf "Destination #%d (%s) has an unsupported protocol: %s." $i $destination.name $destination.protocol) }}
        {{- $msg = append $msg "The protocol must be either \"grpc\" or \"http\"" }}
        {{- $msg = append $msg "Please set:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" $destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg "    protocol: otlp / http" }}
        {{- fail (join "\n" $msg) }}
      {{- end }}

      {{/* Check if OTLP destination using Grafana Cloud OTLP gateway has protocol set */}}
      {{- if $destination.url }}
        {{- if and (ne $destination.protocol "http") (regexMatch "otlp-gateway-.+grafana\\.net" $destination.url) }}
          {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud OTLP gateway but has incorrect protocol '%s'. The gateway requires 'http'.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    protocol: http" $i $destination.name ($destination.protocol | default "grpc (default)") $destination.name $destination.url) }}
        {{- end }}

        {{/* Check if OTLP destination using Grafana Cloud Tempo checks */}}
        {{- if and (regexMatch "tempo-.+grafana\\.net" $destination.url) }}
          {{- if ne ($destination.protocol | default "grpc") "grpc" }}
            {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud Traces but has incorrect protocol '%s'. Grafana Cloud Traces requires 'grpc'.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    protocol: grpc" $i $destination.name $destination.protocol $destination.name $destination.url) }}
          {{- end }}
          {{- if eq (dig "metrics" "enabled" true $destination) true }}
            {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud Traces but has metrics enabled. Tempo only supports traces.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    metrics:\n      enabled: false" $i $destination.name $destination.name $destination.url) }}
          {{- end }}
          {{- if eq (dig "logs" "enabled" true $destination) true }}
            {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud Traces but has logs enabled. Tempo only supports traces.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    logs:\n      enabled: false" $i $destination.name $destination.name $destination.url) }}
          {{- end }}
          {{- if eq (dig "traces" "enabled" true $destination) false }}
            {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud Traces but has traces disabled.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    traces:\n      enabled: true" $i $destination.name $destination.name $destination.url) }}
          {{- end }}
        {{- end }}
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
