{{- define "integrations.postgresql.validate" }}
  {{- range $instance := $.Values.postgresql.instances }}
    {{- $defaultValues := fromYaml ($.Files.Get "integrations/postgresql-values.yaml") }}
    {{- include "integrations.postgresql.instance.validate" (dict "instance" (mergeOverwrite $defaultValues $instance (dict "type" "integration.postgresql"))) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.postgresql.instance.validate" }}
{{- $metricsEnabled := (dig "metrics" "enabled" true .instance) }}
{{- if $metricsEnabled }}
  {{- $missingExporterDetails := false }}
  {{- if not .instance.exporter }}
    {{ $missingExporterDetails = true }}
  {{- else if and (not .instance.exporter.dataSourceName) (not .instance.exporter.dataSource.host) }}
    {{ $missingExporterDetails = true }}
  {{- end }}
  {{- if $missingExporterDetails }}
    {{- $msg := list "" "Missing data source details for PostgreSQL exporter." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  postgresql:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        exporter:" }}
    {{- $msg = append $msg "          dataSourceName: \"user:pass@database.namespace.svc:3306\"" }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        exporter:" }}
    {{- $msg = append $msg "          dataSource:" }}
    {{- $msg = append $msg "            host: database.namespace.svc" }}
    {{- $msg = append $msg "            port: 3306" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- $dbO11yEnabled := (dig "databaseObservability" "enabled" true .instance) }}
{{- if and $dbO11yEnabled (not $metricsEnabled) }}
  {{- $msg := list "" "Enabling Database Observability for PostgreSQL requires exporter metrics." }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "integrations:" }}
  {{- $msg = append $msg "  postgresql:" }}
  {{- $msg = append $msg "    instances:" }}
  {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
  {{- $msg = append $msg "        metrics:" }}
  {{- $msg = append $msg "          enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- if and .instance.logs.enabled (not .instance.logs.labelSelectors) }}
  {{- $msg := list "" "The PostgreSQL integration requires a label selector" }}
  {{- $msg = append $msg "For example, please set:" }}
  {{- $msg = append $msg "integrations:" }}
  {{- $msg = append $msg "  postgresql:" }}
  {{- $msg = append $msg "    instances:" }}
  {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
  {{- $msg = append $msg "        logs:" }}
  {{- $msg = append $msg "          labelSelectors:" }}
  {{- $msg = append $msg (printf "            app.kubernetes.io/name: %s" .instance.name) }}
  {{- $msg = append $msg "OR" }}
  {{- $msg = append $msg "          labelSelectors:" }}
  {{- $msg = append $msg "            app.kubernetes.io/name: [postgresql-one, postgresql-two]" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{- define "secrets.list.integration.postgresql" }}
- exporter.dataSource.auth.username
- exporter.dataSource.auth.password
{{- end }}
