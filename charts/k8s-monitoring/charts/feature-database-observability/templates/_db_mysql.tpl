{{- define "databaseObservability.mysql.validate" }}
  {{- range $instance := $.Values.mysql.instances }}
    {{- include "databaseObservability.mysql.instance.validate" (deepCopy $ | merge (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "databaseObservability.mysql.instance.validate" }}
{{- if .instance.exporter.enabled }}
  {{- if and (not .instance.dataSource.rawString) (not .instance.dataSource.host) }}
    {{- $msg := list "" "Missing data source details for MySQL exporter." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "databaseObservability:" }}
    {{- $msg = append $msg "  mysql:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        dataSource:" }}
    {{- $msg = append $msg "          rawString: \"user:pass@database.namespace.svc:3306\"" }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        dataSource:" }}
    {{- $msg = append $msg "          host: database.namespace.svc" }}
    {{- $msg = append $msg "          port: 3306" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- if .instance.queryAnalysis.enabled }}
  {{- if and (not .instance.dataSource.rawString) (not .instance.dataSource.host) }}
    {{- $msg := list "" "Missing data source details for MySQL query analysis." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "databaseObservability:" }}
    {{- $msg = append $msg "  mysql:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        dataSource:" }}
    {{- $msg = append $msg "          rawString: \"user:pass@database.namespace.svc:3306\"" }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        dataSource:" }}
    {{- $msg = append $msg "          host: database.namespace.svc" }}
    {{- $msg = append $msg "          port: 3306" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- if and .instance.logs.enabled (not .instance.logs.labelSelectors) }}
  {{- $msg := list "" "The MySQL integration requires a label selector" }}
  {{- $msg = append $msg "For example, please set:" }}
  {{- $msg = append $msg "databaseObservability:" }}
  {{- $msg = append $msg "  instances:" }}
  {{- $msg = append $msg (printf "    %s:" .instance.name) }}
  {{- $msg = append $msg "      logs:" }}
  {{- $msg = append $msg "        labelSelectors:" }}
  {{- $msg = append $msg (printf "          app.kubernetes.io/name: %s" .instance.name) }}
  {{- $msg = append $msg "OR" }}
  {{- $msg = append $msg "        labelSelectors:" }}
  {{- $msg = append $msg "          app.kubernetes.io/name: [mysql-one, mysql-two]" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{- define "secrets.list.databaseObservability.mysql" }}
- dataSource.auth.username
- dataSource.auth.password
{{- end }}
