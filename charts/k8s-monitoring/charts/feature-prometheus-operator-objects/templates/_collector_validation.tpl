{{/* Validates that the Alloy instance is appropriate for the given Prometheus Operator Objects settings */}}
{{/* Inputs: Values (Prometheus Operator Objects values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.prometheusOperatorObjects.collector.validate" -}}
{{- $stabilityLevel := (dig "alloy" "stabilityLevel" "generally-available" .Collector)}}
{{- if .Values.scrapeConfigs.enabled }}
  {{- if ne $stabilityLevel "experimental" }}
    {{- $msg := list "" "The Prometheus Operator Objects feature requires Alloy to use the experimental stability level when using ScrapeConfigs." }}
    {{- $msg = append $msg "Please set:"}}
    {{- $msg = append $msg (printf "%s:" .CollectorName) }}
    {{- $msg = append $msg "  alloy:"}}
    {{- $msg = append $msg "    stabilityLevel: experimental"}}
    {{- fail (join "\n" $msg) }}
  {{- end -}}
{{- end -}}
{{- end -}}
