{{- define "feature.profiling.validate" }}
{{- if and (not .Values.ebpf.enabled) (not .Values.java.enabled) (not .Values.pprof.enabled) }}
  {{- $msg := list "" "At least one profiling type must be enabled for this feature to work." }}
  {{- $msg = append $msg "Please enable one or more:" }}
  {{- $msg = append $msg "profiling:" }}
  {{- $msg = append $msg "  ebpf:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "  java:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- $msg = append $msg "  pprof:" }}
  {{- $msg = append $msg "    enabled: true" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
