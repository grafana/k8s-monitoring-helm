{{/*
Warns when a destination's authentication type is being inferred as "basic" because a username and
password were provided without an explicit "auth.type". Mirrors the inference in "secrets.authType"
so users are aware authentication was enabled implicitly.
*/}}
{{- define "destinations.notes.inferredAuth" }}
{{- $affected := list }}
{{- range $destinationName, $destination := .Values.destinations }}
  {{- if and (not (dig "auth" "type" "" $destination)) (eq (include "secrets.authType" $destination) "basic") }}
    {{- $affected = append $affected $destinationName }}
  {{- end }}
{{- end }}
{{- if $affected }}

⚠️ Inferring the authentication type as "basic" because a username and password were provided
without an explicit "auth.type"

Affected destination(s):
{{- range $name := $affected }}
* {{ $name }}
{{- end }}
{{- end }}
{{- end }}
