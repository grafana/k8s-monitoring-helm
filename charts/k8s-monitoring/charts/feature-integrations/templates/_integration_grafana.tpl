{{- define "integrations.grafana.validate" }}
  {{- range $instance := $.Values.grafana.instances }}
    {{- include "integrations.grafana.instance.validate" (merge $ (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.grafana.instance.validate" }}
  {{- if not .instance.labelSelectors }}
    {{- $msg := list "" "The Grafana integration requires a label selector" }}
    {{- $msg = append $msg "For example, please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  grafana:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg (printf "          app.kubernetes.io/name: %s" .instance.name) }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg "          app.kubernetes.io/name: [grafana-one, grafana-two]" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
