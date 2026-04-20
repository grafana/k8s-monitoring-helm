{{/*
duration_to_seconds converts a Go-style duration string to total seconds.
Supports: "Ns", "Nm", "Nh", "NhNm", "NmNs", "NhNmNs"
Example: {{ include "duration_to_seconds" "2m30s" }} => 150
*/}}
{{- define "duration_to_seconds" -}}
{{- $input := toString . -}}
{{- $hours := 0 -}}
{{- $minutes := 0 -}}
{{- $seconds := 0 -}}
{{- if regexMatch "\\d+h" $input -}}
  {{- $hours = trimSuffix "h" (regexFind "\\d+h" $input) | atoi -}}
{{- end -}}
{{- if regexMatch "\\d+m" $input -}}
  {{- $minutes = trimSuffix "m" (regexFind "\\d+m" $input) | atoi -}}
{{- end -}}
{{- if regexMatch "\\d+s" $input -}}
  {{- $seconds = trimSuffix "s" (regexFind "\\d+s" $input) | atoi -}}
{{- end -}}
{{- add (mul $hours 3600) (mul $minutes 60) $seconds -}}
{{- end -}}

{{/*
enforce_min_scrape_interval returns the interval, clamped up to the minimum if set.
If min is empty, acts as a passthrough.
If interval is empty, returns the min (or empty if min is also empty).
Usage: {{ include "enforce_min_scrape_interval" (dict "interval" "30s" "min" "60s") }}
*/}}
{{- define "enforce_min_scrape_interval" -}}
{{- $interval := .interval -}}
{{- $min := .min -}}
{{- if not $min -}}
  {{- $interval -}}
{{- else if not $interval -}}
  {{- $min -}}
{{- else -}}
  {{- $intervalSec := include "duration_to_seconds" $interval | atoi -}}
  {{- $minSec := include "duration_to_seconds" $min | atoi -}}
  {{- if lt $intervalSec $minSec -}}
    {{- $min -}}
  {{- else -}}
    {{- $interval -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
check_scrape_interval_floor returns a warning line if the interval is below the floor.
Usage: {{ include "check_scrape_interval_floor" (dict "name" "kubelet.scrapeInterval" "interval" "30s" "min" "60s" "minSec" 60) }}
*/}}
{{- define "check_scrape_interval_floor" -}}
{{- if and .interval .min -}}
  {{- $intervalSec := include "duration_to_seconds" .interval | atoi -}}
  {{- if lt $intervalSec (.minSec | int) -}}
  - {{ .name }}: {{ .interval }} → {{ .min }}
  {{- end -}}
{{- end -}}
{{- end -}}
