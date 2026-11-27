{{- define "feature.podLogsViaLoki.validate" }}
  {{- if and .Values.cri.maxPartialLineSizeTruncate (le (int64 .Values.cri.maxPartialLineSize) 0) }}
    {{- fail "Set podLogsViaLoki.cri.maxPartialLineSize to a positive number of bytes when podLogsViaLoki.cri.maxPartialLineSizeTruncate is true." }}
  {{- end }}
{{- end }}
