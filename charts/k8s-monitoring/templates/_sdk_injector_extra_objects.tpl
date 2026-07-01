{{- define "sdkInjector.alloyConfigMapWriterRoleName" -}}
{{- printf "%s-sdk-injector" (include "collector.alloy.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Temporary SDK Injector RBAC shim.

This can be removed once the Alloy chart change lands that allows the SDK
Injector ConfigMap writer RBAC flag to be set directly instead of rendering this
via extraObjects.

Do not use Alloy `spec.rbac.rules` for this temporary permission. Without
`spec.rbac.namespaces`, Alloy renders those rules as cluster-scoped RBAC; setting
`spec.rbac.namespaces` would scope every Alloy RBAC rule, not just this SDK
Injector ConfigMap writer rule. Rendering a separate Role/RoleBinding keeps only
this permission scoped to the namespace where the Alloy collector is deployed.
*/}}
{{- define "sdkInjector.extraObjects" -}}
{{- $sdkInjector := index .Values "sdkInjector" | default dict }}
{{- if $sdkInjector.enabled }}
{{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
{{- $values := dict "Values" $.Values "Files" $.Files "Release" $.Release "Chart" $.Chart "collectorName" $collectorName }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "sdkInjector.alloyConfigMapWriterRoleName" $values }}
  namespace: {{ include "helper.namespace" $ }}
  labels:{{ include "collector.alloy.labels" $values | trim | nindent 4 }}
    app.kubernetes.io/component: rbac
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "sdkInjector.alloyConfigMapWriterRoleName" $values }}
  namespace: {{ include "helper.namespace" $ }}
  labels:{{ include "collector.alloy.labels" $values | trim | nindent 4 }}
    app.kubernetes.io/component: rbac
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "sdkInjector.alloyConfigMapWriterRoleName" $values }}
subjects:
  - kind: ServiceAccount
    name: {{ include "collector.alloy.serviceAccountName" $values }}
    namespace: {{ include "helper.namespace" $ }}
{{- end }}
{{- end }}
{{- end }}
