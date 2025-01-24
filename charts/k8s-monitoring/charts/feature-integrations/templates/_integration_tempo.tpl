{{- define "integrations.tempo.validate" }}
  {{- range $instance := $.Values.tempo.instances }}
    {{- include "integrations.tempo.instance.validate" (merge $ (dict "instance" $instance)) | nindent 2 }}
  {{- end }}
{{- end }}

{{- define "integrations.tempo.instance.validate" }}
  {{- if not .instance.labelSelectors }}
    {{- $msg := list "" "The tempo integration requires a label selector" }}
    {{- $msg = append $msg "For example, please set:" }}
    {{- $msg = append $msg "integrations:" }}
    {{- $msg = append $msg "  tempo:" }}
    {{- $msg = append $msg "    instances:" }}
    {{- $msg = append $msg (printf "      - name: %s" .instance.name) }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg (printf "          app.kubernetes.io/name: %s" .instance.name) }}
    {{- $msg = append $msg "OR" }}
    {{- $msg = append $msg "        labelSelectors:" }}
    {{- $msg = append $msg "          app.kubernetes.io/name: [tempo-one, tempo-two]" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
