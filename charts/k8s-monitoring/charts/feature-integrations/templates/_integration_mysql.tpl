{{- define "integrations.mysql.validate" }}
  {{- range $instance := $.Values.mysql.instances }}
    {{- include "integrations.mysql.instance.validate" (merge $ (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.mysql.instance.validate" }}
{{- if .instance.exporter.enabled }}
  {{- if and (not .instance.exporter.dataSourceName) (not (and .instance.exporter.dataSource.username .instance.exporter.dataSource.password .instance.exporter.dataSource.host)) }}
    {{- $msg := list "" "Missing data source details for MySQL exporter." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  mysql:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
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
{{- if and .instance.logs.enabled (not .instance.logs.labelSelectors) }}
  {{- $msg := list "" "The MySQL integration requires a label selector" }}
  {{- $msg = append $msg "For example, please set:" }}
  {{- $msg = append $msg "integrations:" }}
  {{- $msg = append $msg "  mysql:" }}
  {{- $msg = append $msg "    instances:" }}
  {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
  {{- $msg = append $msg "        logs:" }}
  {{- $msg = append $msg "          labelSelectors:" }}
  {{- $msg = append $msg (printf "            app.kubernetes.io/name: %s" .instance.name) }}
  {{- $msg = append $msg "OR" }}
  {{- $msg = append $msg "          labelSelectors:" }}
  {{- $msg = append $msg "            app.kubernetes.io/name: [mysql-one, mysql-two]" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{- define "secrets.list.integration.mysql" }}
- exporter.dataSource.auth.username
- exporter.dataSource.auth.password
{{- end }}
