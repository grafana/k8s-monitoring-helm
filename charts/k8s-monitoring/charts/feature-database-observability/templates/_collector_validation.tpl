{{/* Validates that the Alloy instance is appropriate for the given Database Observability settings */}}
{{/* Inputs: Values (Database Observability values), Collector (Alloy values), CollectorName (string) */}}
{{- define "feature.databaseObservability.collector.validate" -}}
{{- $stabilityLevel := (dig "alloy" "stabilityLevel" "generally-available" .Collector)}}
{{- range $instance := $.Values.mysql.instances }}
  {{- if $instance.queryAnalysis.enabled }}
    {{- if ne $stabilityLevel "experimental" }}
      {{- $msg := list "" "Database Observability feature requires Alloy to use the experimental stability level when using the query analysis features." }}
      {{- $msg = append $msg "Please set:"}}
      {{- $msg = append $msg (printf "%s:" $.CollectorName) }}
      {{- $msg = append $msg "  alloy:"}}
      {{- $msg = append $msg "    stabilityLevel: experimental"}}
      {{- fail (join "\n" $msg) }}
    {{- end -}}
  {{- end }}
{{- end }}
{{- end -}}
