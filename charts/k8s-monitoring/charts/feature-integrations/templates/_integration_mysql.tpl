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
