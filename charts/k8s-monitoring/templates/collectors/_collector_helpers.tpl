{{- define "collectors.list" -}}
- alloy-metrics
- alloy-singleton
- alloy-logs
- alloy-receiver
- alloy-profiles
{{- end }}

{{- define "collectors.list.enabled" -}}
{{- range $collector := ((include "collectors.list" .) | fromYamlArray ) }}
  {{- if (index $.Values $collector).enabled }}
- {{ $collector }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Inputs: Values (all values), name (collector name), feature (feature name) */}}
{{- define "collectors.require_collector" -}}
{{- if not (index .Values .name).enabled }}
  {{- $msg := list "" }}
  {{- $msg = append $msg (printf "The %s feature requires the use of the %s collector." .feature .name ) }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "Please enable it by setting:" }}
  {{- $msg = append $msg (printf "%s:" .name) }}
  {{- $msg = append $msg "  enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{/* Inputs: Values (all values), name (collector name), feature (feature name), portNumber, portName, portProtocol */}}
{{- define "collectors.require_extra_port" -}}
{{- $found := false -}}
{{- range (index .Values .name).alloy.extraPorts -}}
  {{- if eq (int .targetPort) (int $.portNumber) }}
    {{- $found = true -}}
  {{- end }}
{{- end }}
{{- if not $found }}
  {{- $msg := list "" }}
  {{- $msg = append $msg (printf "The %s feature requires that port %d to be open on the %s collector." .feature (.portNumber | int) .name ) }}
  {{- $msg = append $msg "" }}
  {{- $msg = append $msg "Please enable it by setting:" }}
  {{- $msg = append $msg (printf "%s:" .name) }}
  {{- $msg = append $msg "  alloy:" }}
  {{- $msg = append $msg "    extraPorts:" }}
  {{- $msg = append $msg (printf "      - name: %s" .portName) }}
  {{- $msg = append $msg (printf "        port: %d" (.portNumber | int)) }}
  {{- $msg = append $msg (printf "        targetPort: %d" (.portNumber | int)) }}
  {{- $msg = append $msg (printf "        protocol: %s" .portProtocol) }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
