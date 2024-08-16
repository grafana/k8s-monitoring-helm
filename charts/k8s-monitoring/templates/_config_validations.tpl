{{- define "checkForValidConfiguration" -}}
{{- if and .Values.logs.enabled .Values.logs.pod_logs.enabled }}
  {{- if eq .Values.logs.pod_logs.gatherMethod "volumes" }}
    {{- if ne (index .Values "alloy-logs").controller.type "daemonset" }}
{{/*
Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "volumes", Grafana Alloy for Logs must be a Daemonset. Otherwise, logs will be missing!
Please set:
logs:
  pod_logs:
    gatherMethod: api
or
alloy-logs:
  controller:
    type: daemonset
*/}}
      {{ fail "Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: \"volumes\", Grafana Alloy for Logs must be a Daemonset. Otherwise, logs will be missing!\nPlease set:\nlogs:\n  pod_logs:\n    gatherMethod: api\n  or\nalloy-logs:\n  controller:\n    type: daemonset"}}
    {{- end }}
    {{- if (index .Values "alloy-logs").alloy.clustering.enabled }}
{{/*
Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "volumes", Grafana Alloy for Logs should not utilize clustering. Otherwise, performance will suffer!
Please set:
alloy-logs:
  alloy:
    clustering:
      enabled: false
*/}}
      {{ fail "Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: \"volumes\", Grafana Alloy for Logs should not utilize clustering. Otherwise, performance will suffer!\nPlease set:\nalloy-logs:\n  alloy:\n    clustering:\n      enabled: false"}}
    {{- end }}

  {{- else if eq .Values.logs.pod_logs.gatherMethod "api" }}
    {{- if not (index .Values "alloy-logs").alloy.clustering.enabled }}
      {{- if eq (index .Values "alloy-logs").controller.type "daemonset" }}
{{/*
Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "api" and the Grafana Alloy for Logs is a Daemonset, you must enable clustering. Otherwise, log files may be duplicated!
Please set:
alloy-logs:
  alloy:
    clustering:
      enabled: true
*/}}
        {{ fail "Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: \"api\" and the Grafana Alloy for Logs is a Daemonset, you must enable clustering. Otherwise, log files may be duplicated!\nPlease set:\nalloy-logs:\n  alloy:\n    clustering:\n      enabled: true"}}
      {{- end }}

      {{- if gt (int (index .Values "alloy-logs").controller.replicas) 1 }}
{{/*
Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: "api" and the Grafana Alloy for Logs has multiple replicas, you must enable clustering. Otherwise, log files will be duplicated!
Please set:
alloy-logs:
  alloy:
    clustering:
      enabled: true
*/}}
        {{ fail "Invalid configuration for gathering pod logs! When using logs.pod_logs.gatherMethod: \"api\" and the Grafana Alloy for Logs has multiple replicas, you must enable clustering. Otherwise, log files will be duplicated!\nPlease set:\nalloy-logs:\n  alloy:\n    clustering:\n      enabled: true"}}
      {{- end }}

    {{- end -}}
  {{- end -}}
{{- end -}}

{{- if and .Values.logs.enabled .Values.logs.journal.enabled }}
  {{- if ne (index .Values "alloy-logs").controller.type "daemonset" }}
{{/*
Invalid configuration for gathering journal logs! Grafana Alloy for Logs must be a Daemonset. Otherwise, journal logs will be missing!
Please set:
alloy-logs:
  controller:
    type: daemonset
*/}}
      {{ fail "Invalid configuration for gathering journal logs! Grafana Alloy for Logs must be a Daemonset. Otherwise, journal logs will be missing!\nPlease set:\nalloy-logs:\n  controller:\n    type: daemonset"}}
  {{- end }}
{{- end -}}

{{- $Values := .Values }}
{{- range $alloy := tuple "alloy" "alloy-events" "alloy-logs" "alloy-profiles"}}
  {{- with (index $Values $alloy) }}
    {{- if and .liveDebugging.enabled (not (eq .alloy.stabilityLevel "experimental")) }}
{{/*
To enable Alloy live debugging, you must set the stabilityLevel to "experimental":
alloy-logs:
  alloy:
    stabilityLevel: experimental
*/}}
      {{ fail (printf "To enable Alloy live debugging, you must set the stabilityLevel to \"experimental\":\n%s:\n  alloy:\n    stabilityLevel: experimental" $alloy) }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}
