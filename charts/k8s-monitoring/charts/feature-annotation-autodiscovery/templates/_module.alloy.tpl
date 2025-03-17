{{- define "feature.annotationAutodiscovery.module" }}
declare "annotation_autodiscovery" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
{{- if .Values.pods.enabled }}
  {{- include "feature.annotationAutodiscovery.pods" . | indent 2 }}
{{- end }}
{{- if .Values.services.enabled }}
{{- include "feature.annotationAutodiscovery.services" . | indent 2 }}
{{- end }}

{{- $targets := list }}
{{- if .Values.pods.enabled }}
  {{- $targets = append $targets "discovery.relabel.annotation_autodiscovery_pods.output" }}
{{- end }}
{{- if .Values.services.enabled }}
  {{- $targets = append $targets "discovery.relabel.annotation_autodiscovery_services.output" }}
{{- end }}

  discovery.relabel "annotation_autodiscovery_http" {
    targets = array.concat({{ $targets | join ", " }})
    rule {
      source_labels = ["__scheme__"]
      regex = "https"
      action = "drop"
    }
  }

  discovery.relabel "annotation_autodiscovery_https" {
    targets = array.concat({{ $targets | join ", " }})
    rule {
      source_labels = ["__scheme__"]
      regex = "https"
      action = "keep"
    }
  }

  prometheus.scrape "annotation_autodiscovery_http" {
    targets = discovery.relabel.annotation_autodiscovery_http.output
    honor_labels = true
{{- if .Values.bearerToken.enabled }}
    bearer_token_file = {{ .Values.bearerToken.token | quote }}
{{- end }}
    clustering {
      enabled = true
    }
{{- $metricRelabelRulesNeeded :=  or .Values.metricsTuning.includeMetrics .Values.metricsTuning.excludeMetrics .Values.extraMetricProcessingRules }}
{{- $metricRelabelRulesNeeded =  or $metricRelabelRulesNeeded (and .Values.pods.enabled (or .Values.pods.staticLabels .Values.pods.staticLabelsFrom)) }}
{{- $metricRelabelRulesNeeded =  or $metricRelabelRulesNeeded (and .Values.services.enabled (or .Values.services.staticLabels .Values.services.staticLabelsFrom)) }}
{{ if $metricRelabelRulesNeeded }}
    forward_to = [prometheus.relabel.annotation_autodiscovery.receiver]
{{- else }}
    forward_to = argument.metrics_destinations.value
{{- end }}
  }

  prometheus.scrape "annotation_autodiscovery_https" {
    targets = discovery.relabel.annotation_autodiscovery_https.output
    honor_labels = true
{{- if .Values.bearerToken.enabled }}
    bearer_token_file = {{ .Values.bearerToken.token | quote }}
{{- end }}
    tls_config {
      insecure_skip_verify = true
    }
    clustering {
      enabled = true
    }
{{ if $metricRelabelRulesNeeded }}
    forward_to = [prometheus.relabel.annotation_autodiscovery.receiver]
  }

  prometheus.relabel "annotation_autodiscovery" {
    max_cache_size = {{ .Values.maxCacheSize | default .Values.global.maxCacheSize | int }}
{{- if .Values.metricsTuning.includeMetrics }}
    rule {
      source_labels = ["__name__"]
      regex = "up|scrape_samples_scraped|{{ join "|" .Values.metricsTuning.includeMetrics }}"
      action = "keep"
    }
{{- end }}
{{- if .Values.metricsTuning.excludeMetrics }}
    rule {
      source_labels = ["__name__"]
      regex = {{ join "|" .Values.metricsTuning.excludeMetrics | quote }}
      action = "drop"
    }
{{- end }}
{{- if .Values.pods.enabled }}
{{- range $k, $v := .Values.pods.staticLabels }}
    rule {
      source_labels = ["temp_source"]
      regex = "pod"
      target_label = {{ $k | quote }}
      replacement = {{ $v | quote }}
    }
{{- end }}
{{- range $k, $v := .Values.pods.staticLabelsFrom }}
    rule {
      source_labels = ["temp_source"]
      regex = "pod"
      target_label = {{ $k | quote }}
      replacement = {{ $v }}
    }
{{- end }}
{{- end }}
{{- if .Values.services.enabled }}
{{- range $k, $v := .Values.services.staticLabels }}
    rule {
      source_labels = ["temp_source"]
      regex = "service"
      target_label = {{ $k | quote }}
      replacement = {{ $v | quote }}
    }
{{- end }}
{{- range $k, $v := .Values.services.staticLabelsFrom }}
    rule {
      source_labels = ["temp_source"]
      regex = "service"
      target_label = {{ $k | quote }}
      replacement = {{ $v }}
    }
{{- end }}
{{- end }}
    rule {
      action = "labeldrop"
      regex = "temp_source"
    }
{{- if .Values.extraMetricProcessingRules }}
{{ .Values.extraMetricProcessingRules | indent 4 }}
{{- end }}
{{- end }}
    forward_to = argument.metrics_destinations.value
  }
}
{{- end -}}

{{- define "feature.annotationAutodiscovery.alloyModules" }}{{- end }}
