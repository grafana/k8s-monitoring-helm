{{- define "feature.podLogs.validate" }}
{{- if and (eq .Values.gatherMethod "OpenShiftClusterLogForwarder") (eq .Values.global.platform "openshift") }}
{{- $msg := list "" "The OpenShiftClusterLogForwarder gather method is only available when running in OpenShift." }}
{{- $msg = append $msg "To set the platform, please set:" }}
{{- $msg = append $msg "global:" }}
{{- $msg = append $msg "  platform: \"openshift\"" }}
{{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}
