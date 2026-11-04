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
Best-effort check that the configured labelMatchers actually select running pods in the given namespace.
Uses `lookup`, which returns nothing during `helm template`/`--dry-run` (no cluster connection), so this
check is skipped in those cases. It also only runs when both a namespace and labelMatchers are set.
Input: dict with "namespace", "labelMatchers", and "serviceName".
*/}}
{{- define "feature.validateLabelMatchersFindPods" -}}
{{- if and .namespace .labelMatchers }}
{{- $pods := (lookup "v1" "Pod" .namespace "").items }}
{{- if $pods }}
{{- $found := false }}
{{- range $pod := $pods }}
  {{- if not $found }}
    {{- $podLabels := $pod.metadata.labels | default dict }}
    {{- $matches := true }}
    {{- range $label, $value := $.labelMatchers }}
      {{- if ne (dig $label "" $podLabels) ($value | toString) }}
        {{- $matches = false }}
      {{- end }}
    {{- end }}
    {{- if $matches }}{{- $found = true }}{{- end }}
  {{- end }}
{{- end }}
{{- if not $found }}
  {{- $msg := list "" (printf "Unable to find any %s pods matching the configured labelMatchers in namespace %q." .serviceName .namespace) }}
  {{- $msg = append $msg "The configured labelMatchers were:" }}
  {{- range $label, $value := .labelMatchers }}
    {{- $msg = append $msg (printf "  %s: %s" $label ($value | toString)) }}
  {{- end }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg (printf "Please verify the namespace and labelMatchers point to a running %s." .serviceName) }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
{{- end }}
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
