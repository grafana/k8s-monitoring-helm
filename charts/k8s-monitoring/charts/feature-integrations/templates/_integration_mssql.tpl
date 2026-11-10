{{- define "integrations.mssql.validate" }}
  {{- range $instance := $.Values.mssql.instances }}
    {{- $defaultValues := fromYaml ($.Files.Get "integrations/mssql-values.yaml") }}
    {{- include "integrations.mssql.instance.validate" (dict "instance" (mergeOverwrite $defaultValues $instance (dict "type" "integration.mssql"))) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.mssql.instance.validate" }}
{{- $metricsEnabled := (dig "metrics" "enabled" true .instance) }}
{{- if $metricsEnabled }}
  {{- $missingExporterDetails := false }}
  {{- if not .instance.exporter }}
    {{ $missingExporterDetails = true }}
  {{- else if and (not .instance.exporter.dataSourceName) (not .instance.exporter.dataSourceNameFrom) (not (dig "exporter" "dataSource" "host" "" .instance)) }}
    {{ $missingExporterDetails = true }}
  {{- end }}
  {{- if $missingExporterDetails }}
    {{- $msg := list "" "Missing data source details for MSSQL exporter." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  mssql:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        exporter:" }}
    {{- $msg = append $msg "          dataSourceName: \"sqlserver://user:pass@database.namespace.svc:1433\"" }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        exporter:" }}
    {{- $msg = append $msg "          dataSource:" }}
    {{- $msg = append $msg "            host: database.namespace.svc" }}
    {{- $msg = append $msg "            port: 1433" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- $dbO11yEnabled := (dig "databaseObservability" "enabled" true .instance) }}
{{- if and $dbO11yEnabled (not $metricsEnabled) }}
  {{- $msg := list "" "Enabling Database Observability for MSSQL requires exporter metrics." }}
  {{- $msg = append $msg "Please set:" }}
  {{- $msg = append $msg "integrations:" }}
  {{- $msg = append $msg "  mssql:" }}
  {{- $msg = append $msg "    instances:" }}
  {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
  {{- $msg = append $msg "        metrics:" }}
  {{- $msg = append $msg "          enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- if $dbO11yEnabled }}
  {{- range $label, $_ := (dig "databaseObservability" "labels" dict .instance) }}
    {{- if has $label (list "job" "instance" "dsn") }}
      {{- fail (printf "\nThe label %q in databaseObservability.labels for instance %q is reserved and cannot be overridden.\nReserved labels: job, instance, dsn.\nUse `jobLabel` to change the job value." $label $.instance.name) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if and .instance.logs.enabled (not .instance.logs.labelSelectors) }}
  {{- $msg := list "" "The MSSQL integration requires a label selector" }}
  {{- $msg = append $msg "For example, please set:" }}
  {{- $msg = append $msg "integrations:" }}
  {{- $msg = append $msg "  mssql:" }}
  {{- $msg = append $msg "    instances:" }}
  {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
  {{- $msg = append $msg "        logs:" }}
  {{- $msg = append $msg "          labelSelectors:" }}
  {{- $msg = append $msg (printf "            app.kubernetes.io/name: %s" .instance.name) }}
  {{- $msg = append $msg "OR" }}
  {{- $msg = append $msg "          labelSelectors:" }}
  {{- $msg = append $msg "            app.kubernetes.io/name: [mssql-one, mssql-two]" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{- define "secrets.list.integration.mssql" }}
- exporter.dataSource.auth.username
- exporter.dataSource.auth.password
{{- end }}
