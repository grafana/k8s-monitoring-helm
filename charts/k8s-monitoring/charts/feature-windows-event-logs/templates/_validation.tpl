{{- define "feature.windowsEventLogs.validate" }}
{{- if not .Values.sources }}
  {{- $msg := list "" "The Windows Event Logs feature requires at least one source." }}
  {{- $msg = append $msg "Please set one:"}}
  {{- $msg = append $msg "windowsEventLogs:" }}
  {{- $msg = append $msg "  sources:" }}
  {{- $msg = append $msg "    - name: application" }}
  {{- $msg = append $msg "      eventLogName: Application" }}
  {{- $msg = append $msg "      jobLabel: integrations/windows-application-logs" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- $names := list }}
{{- range $source := .Values.sources }}
  {{- if not $source.name }}
    {{- fail "Each entry in `windowsEventLogs.sources` must set a `name`, which is used for the Alloy component label and bookmark file name." }}
  {{- end }}
  {{- if has $source.name $names }}
    {{- fail (printf "Duplicate Windows Event Logs source name %q. Each `windowsEventLogs.sources` entry must have a unique `name`." $source.name) }}
  {{- end }}
  {{- $names = append $names $source.name }}
  {{- $xpathQuery := $source.xpathQuery | default "*" }}
  {{- if and (not $source.eventLogName) (eq $xpathQuery "*") }}
    {{- fail (printf "Windows Event Logs source %q must set `eventLogName`, or an XML-form `xpathQuery` that specifies the channel to read from." $source.name) }}
  {{- end }}
{{- end }}
{{- end }}
