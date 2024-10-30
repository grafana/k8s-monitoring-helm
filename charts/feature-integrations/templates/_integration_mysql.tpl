{{- define "integrations.mysql.type.metrics" }}true{{- end }}
{{- define "integrations.mysql.type.logs" }}false{{- end }}

{{- define "integrations.mysql.module.metrics" }}
declare "mysql_integration" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
  {{- range $instance := $.Values.mysql.instances }}
    {{- include "integrations.mysql.include.metrics" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
}
{{- end }}

{{- define "integrations.mysql.include.metrics" }}
{{- $defaultValues := "integrations/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- with merge .instance $defaultValues (dict "type" "integration.mysql") }}
{{- if .exporter.enabled }}
{{- if eq (include "secrets.usesKubernetesSecret" .) "true" }}
  {{- include "secret.alloy" (deepCopy $ | merge (dict "object" .)) | nindent 0 }}
{{- end }}
prometheus.exporter.mysql {{ include "helper.alloy_name" .name | quote }} {
{{- if .exporter.dataSourceName }}
  data_source_name  = {{ .exporter.dataSourceName | quote }}
{{- else }}
  {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.username")) "true" }}
    {{- if eq (include "secrets.usesSecret" (dict "object" . "key" "exporter.dataSource.auth.password")) "true" }}
  data_source_name = string.format("%s:%s@(%s:%d)/",
    {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }},
    {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.password") }},
    {{ .exporter.dataSource.host | quote }},
    {{ .exporter.dataSource.port | int }},
  )
    {{- else }}
  data_source_name = string.format("%s@(%s:%d)/",
    {{ include "secrets.read" (dict "object" . "key" "exporter.dataSource.auth.username" "nonsensitive" true) }},
    {{ .exporter.dataSource.host | quote }},
    {{ .exporter.dataSource.port | int }},
  )
    {{- end }}
  {{- else }}
  data_source_name = string.format("%s:%d/", {{ .exporter.dataSource.host | quote }}, {{ .exporter.dataSource.port | int }})
  {{- end }}
{{- end }}
  enable_collectors = {{ .exporter.collectors | toJson }}
}

{{- $metricAllowList := .metricsTuning.includeMetrics }}
{{- $metricDenyList := .metricsTuning.excludeMetrics }}
prometheus.scrape {{ include "helper.alloy_name" .name | quote }} {
  targets    = prometheus.exporter.mysql.{{ include "helper.alloy_name" .name }}.targets
  job_name   = "integration/mysql"
{{- if or (not (empty $metricAllowList)) (not (empty $metricDenyList)) }}
  forward_to = prometheus.relabel.{{ include "helper.alloy_name" .name }}.output
}

promtheus.relabel {{ include "helper.alloy_name" .name | quote }} {
    max_cache_size = {{ .maxCacheSize | default $.Values.global.maxCacheSize | int }}
{{- if $metricAllowList }}
  rule {
    source_labels = ["__name__"]
    regex = "up|{{ $metricAllowList | fromYamlArray | join "|" }}"
    action = "keep"
  }
{{- end }}
{{- if $metricDenyList }}
  rule {
    source_labels = ["__name__"]
    regex = {{ $metricDenyList | join "|" | quote }}
    action = "drop"
  }
{{- end }}
{{- end }}
  forward_to = argument.metrics_destinations.value
}
{{- end }}
{{- end }}
{{- end }}

{{- define "integrations.mysql.validate" }}
  {{- range $instance := $.Values.mysql.instances }}
    {{- include "integrations.mysql.instance.validate" (merge $ (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.mysql.instance.validate" }}
{{- $defaultValues := "integrations/mysql-values.yaml" | .Files.Get | fromYaml }}
{{- with merge .instance $defaultValues }}
{{- if .exporter.enabled }}
  {{- if and (not .exporter.dataSourceName) (not (and .exporter.dataSource.username .exporter.dataSource.password .exporter.dataSource.host)) }}
    {{- $msg := list "" "Missing data source details for MySQL exporter." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  mysql:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .name) }}
    {{- $msg = append $msg "        exporter:" }}
    {{- $msg = append $msg "          dataSourceName: \"user:pass@database.namespace.svc:3306\"" }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        exporter:" }}
    {{- $msg = append $msg "          dataSource:" }}
    {{- $msg = append $msg "            username: user" }}
    {{- $msg = append $msg "            password: pass" }}
    {{- $msg = append $msg "            host: database.namespace.svc" }}
    {{- $msg = append $msg "            port: 3306" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "secrets.list.integration.mysql" }}
- exporter.dataSource.auth.username
- exporter.dataSource.auth.password
{{- end }}
