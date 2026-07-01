{{- define "sdkInjector.beylaConfigMapWriterRoleName" -}}
{{- printf "%s-sdk-injector" (include "beyla.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Temporary SDK Injector RBAC shim.

Beyla writes the annotated injection ConfigMaps that the SDK Injector's
validating webhook gates; the SDK Injector then reads those ConfigMaps. This
grants Beyla's ServiceAccount namespace-scoped permission to write them.

This can be removed once the Beyla chart change lands that allows the SDK
Injector ConfigMap writer RBAC to be set directly instead of rendering this via
extraObjects.

The Role/RoleBinding are rendered in Beyla's namespace, which is where Beyla
writes the ConfigMaps in the default (single-namespace) install. If Beyla and
the SDK Injector are split across namespaces, this grant must follow the
namespace the ConfigMaps are written into.
*/}}
{{- define "sdkInjector.extraObjects" -}}
{{- $sdkInjector := index .Values "sdkInjector" | default dict }}
{{- if and $sdkInjector.enabled .Values.autoInstrumentation.enabled }}
{{- $beyla := .Subcharts.autoInstrumentation.Subcharts.beyla }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "sdkInjector.beylaConfigMapWriterRoleName" $beyla }}
  namespace: {{ include "beyla.namespace" $beyla }}
  labels:{{ include "beyla.labels" $beyla | trim | nindent 4 }}
    app.kubernetes.io/component: rbac
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "sdkInjector.beylaConfigMapWriterRoleName" $beyla }}
  namespace: {{ include "beyla.namespace" $beyla }}
  labels:{{ include "beyla.labels" $beyla | trim | nindent 4 }}
    app.kubernetes.io/component: rbac
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "sdkInjector.beylaConfigMapWriterRoleName" $beyla }}
subjects:
  - kind: ServiceAccount
    name: {{ include "beyla.serviceAccountName" $beyla }}
    namespace: {{ include "beyla.namespace" $beyla }}
{{- end }}
{{- end }}
