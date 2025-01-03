{{- define "integrations.loki.validate" }}
  {{- range $instance := $.Values.loki.instances }}
    {{- include "integrations.loki.instance.validate" (merge $ (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.loki.instance.validate" }}
  {{- if not .instance.labelSelectors }}
    {{- $msg := list "" "The Loki integration requires a label selector" }}
    {{- $msg = append $msg "For example, please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  loki:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg (printf "          app.kubernetes.io/name: %s" .instance.name) }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg "          app.kubernetes.io/name: [loki-one, loki-two]" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
