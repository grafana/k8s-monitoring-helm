{{- define "english_list" }}
{{- if eq (len .) 0 }}
{{- else if eq (len .) 1 }}
{{- index . 0 }}
{{- else if eq (len .) 2 }}
{{- index . 0 }} and {{ index . 1 }}
{{- else }}
{{- $last := index . (sub (len .) 1) }}
{{- $rest := slice . 0 (sub (len .) 1) }}
{{- join ", " $rest }}, and {{ $last }}
{{- end }}
{{- end }}

{{- define "helper.namespace" -}}
{{- .Values.global.namespaceOverride | default .Release.Namespace -}}
{{- end -}}

{{- define "helper.scrapeProtocols" -}}
{{- $protocols := .Values.global.scrapeProtocols -}}
{{- if and .Values.global.scrapeNativeHistograms (not (has "PrometheusProto" $protocols)) -}}
{{- $protocols = prepend $protocols "PrometheusProto" -}}
{{- end -}}
{{ $protocols | toJson }}
{{- end -}}

{{/*
Resolve a histogram scrape setting for this feature. Returns the feature-level
override (`prometheusOperatorObjects.<key>`) when it is set, otherwise falls back
to the cluster-wide default (`global.<key>`). A null/unset override inherits the
global value, so this cannot silently mask an explicit `false` or `0`.
Usage: include "feature.prometheusOperatorObjects.histogramSetting" (dict "root" $ "key" "scrapeNativeHistograms")
*/}}
{{- define "feature.prometheusOperatorObjects.histogramSetting" -}}
{{- $override := index .root.Values .key -}}
{{- if kindIs "invalid" $override -}}
{{- index .root.Values.global .key -}}
{{- else -}}
{{- $override -}}
{{- end -}}
{{- end -}}
