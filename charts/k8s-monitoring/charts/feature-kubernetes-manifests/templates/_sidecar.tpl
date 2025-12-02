{{- define "feature.kubernetesManifests.sidecarContainer" }}
- name: kubernetes-manifest-collector
  {{- with .Values.image }}
    {{- if .digest }}
  image: "{{ dig "image" "registry" .registry $.Values.global }}/{{ .repository }}@{{ .digest }}"
    {{- else }}
  image: "{{ dig "image" "registry" .registry $.Values.global }}/{{ .repository }}:{{ .tag }}"
    {{- end }}
  {{- end }}
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  command:
    - /bin/bash
    - /etc/alloy/collect-manifests.sh
{{- if .Values.namespaces }}
    - --namespaces
    - {{ .Values.namespaces | join "," }}
{{- end }}
{{- if .Values.refreshInterval }}
    - --refresh-interval
    - {{ .Values.refreshInterval | quote }}
{{- end }}
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

