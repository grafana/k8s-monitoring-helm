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

{{- define "helper.relabelCacheArguments" -}}
{{- $settings := . -}}
{{- if not (or .maxCacheSize .cacheTTL) -}}
  {{- $settings = .global -}}
{{- end -}}
{{- if $settings.cacheTTL -}}
max_cache_size = 0
cache_ttl = {{ $settings.cacheTTL | quote }}
{{- else -}}
max_cache_size = {{ $settings.maxCacheSize | int }}
{{- end -}}
{{- end -}}

{{- define "helper.validateRelabelCacheSettings" -}}
{{- $sources := dict .path .values -}}
{{- range $key, $value := .values -}}
  {{- if and (kindIs "map" $value) (ne $key "global") -}}
    {{- $_ := set $sources (printf "%s.%s" $.path $key) $value -}}
  {{- end -}}
{{- end -}}
{{- range $path, $source := $sources -}}
  {{- if and ($source.maxCacheSize | default 0 | int) $source.cacheTTL -}}
    {{- $msg := list "" (printf "%s.maxCacheSize and %s.cacheTTL are mutually exclusive." $path $path) -}}
    {{- $msg = append $msg "Please set only one of them." -}}
    {{- fail (join "\n" $msg) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
