{{- define "integrations.mimir.validate" }}
  {{- range $instance := $.Values.mimir.instances }}
    {{- include "integrations.mimir.instance.validate" (merge $ (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.mimir.instance.validate" }}
  {{- if not .instance.labelSelectors }}
    {{- $msg := list "" "The Mimir integration requires a label selector" }}
    {{- $msg = append $msg "For example, please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  mimir:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg (printf "          app.kubernetes.io/name: %s" .instance.name) }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg "          app.kubernetes.io/name: [mimir-one, mimir-two]" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
