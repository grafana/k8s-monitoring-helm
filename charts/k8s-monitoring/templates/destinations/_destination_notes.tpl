{{/*
Warns when a destination's authentication type is being inferred as "basic" because a username and
password were provided without an explicit "auth.type". Mirrors the inference in "secrets.authType"
so users are aware authentication was enabled implicitly.
*/}}
{{- define "destinations.notes.inferredAuth" }}
{{- $affected := list }}
{{- range $destinationName, $destination := (include "destinations.getEnabled" .Values.destinations | fromYaml) }}
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

{{/* Entry point for router destination-type warnings. Runs destinations.router.notes (see
     _destination_router_validations.tpl) once per enabled router destination, then the
     implicit-selection reminder below once for the whole release. */}}
{{- define "destinations.notes.router" }}
{{- range $destinationName, $destination := (include "destinations.getEnabled" .Values.destinations | fromYaml) }}
  {{- if eq $destination.type "router" }}
    {{- include "destinations.router.notes" (dict "Values" $ "Destination" $destination "DestinationName" $destinationName) }}
  {{- end }}
{{- end }}
{{- include "destinations.notes.routerImplicitSelection" . }}
{{- end }}

{{/*
W-c: routers require explicit "destinations: [<router-name>]" opt-in per feature -- a router is
deliberately excluded from implicit destination selection (see the F7 comment on
destinations.get), so a feature left with no explicit destinations list will never pick one up on
its own, even when the router would otherwise be the only viable destination. Fires at most once,
whenever at least one enabled router exists and at least one enabled feature has no explicit
destinations list.
*/}}
{{- define "destinations.notes.routerImplicitSelection" }}
{{- $hasRouter := false }}
{{- range $destinationName, $destination := (include "destinations.getEnabled" .Values.destinations | fromYaml) }}
  {{- if eq $destination.type "router" }}{{- $hasRouter = true }}{{- end }}
{{- end }}
{{- if $hasRouter }}
  {{- $implicitFeatures := list }}
  {{- range $feature := (include "features.list.enabled" .) | fromYamlArray }}
    {{- $featureValues := index $.Values $feature }}
    {{- if empty ($featureValues.destinations | default list) }}
      {{- $implicitFeatures = append $implicitFeatures $feature }}
    {{- end }}
  {{- end }}
  {{- if $implicitFeatures }}

WARNING: Router destination(s) are configured, but a router requires an explicit "destinations: [<router-name>]" entry on each feature that should use it -- routers are excluded from implicit destination selection. The following enabled feature(s) have no explicit destinations list and will therefore not use a router: {{ join ", " $implicitFeatures }}.
  {{- end }}
{{- end }}
{{- end }}
