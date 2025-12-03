{{- define "feature.kubernetesManifests.sidecarContainer" }}
{{- $globalArgs := "" }}
{{- if .Values.refreshInterval }}
  {{- $globalArgs = printf "--watch-timeout %s" (.Values.refreshInterval | quote) }}
{{- end }}
- name: kubernetes-manifest-collector
  {{- with .Values.image }}
    {{- if .digest }}
  image: "{{ $.Values.global.image.registry | default .registry }}/{{ .repository }}@{{ .digest }}"
    {{- else }}
  image: "{{ $.Values.global.image.registry | default .registry  }}/{{ .repository }}:{{ .tag }}"
    {{- end }}
  {{- end }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  command:
    - /bin/bash
    - -c
    - |
      set -euo pipefail
      pids=()
{{- range $kind := keys .Values.kinds | sortAlpha }}
{{- if dig $kind "gather" false $.Values.kinds }}
{{- if not $.Values.namespaces }}
      bash /etc/alloy/collect-manifests.sh --kind {{ $kind }} {{ $globalArgs }} &
      pids+=("$!")
{{- else }}
{{- range $namespace := $.Values.namespaces }}
      bash /etc/alloy/collect-manifests.sh --kind {{ $kind }} --namespace {{ $namespace | quote }} {{ $globalArgs }} &
      pids+=("$!")
{{- end }}
{{- end }}
{{- end }}
{{- end }}
      trap 'for pid in "${pids[@]}"; do kill "${pid}" 2>/dev/null || true; done' EXIT
      wait -n "${pids[@]}"
  env:
    - name: MANIFEST_DIR
      value: /var/kubernetes-manifests
  volumeMounts:
    - mountPath: /etc/alloy
      name: config
    - mountPath: /var/kubernetes-manifests
      name: kubernetes-manifests
      readOnly: false
{{- end }}

{{- define "feature.kubernetesManifests.volume" }}
- name: kubernetes-manifests
  emptyDir:
    medium: Memory
{{- end }}

{{- define "feature.kubernetesManifests.volumeMount" }}
- mountPath: /var/kubernetes-manifests
  name: kubernetes-manifests
  readOnly: false
{{- end }}
