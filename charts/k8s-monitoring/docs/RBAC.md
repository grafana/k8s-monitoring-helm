# RBAC Rules for the Kubernetes Monitoring Helm Chart
Several components have specialized RBAC rules to perform their work. This document will list the components, and their RBAC definitions.
## Grafana Agent
```yaml
- apiGroups:
    - ''
    - discovery.k8s.io
    - networking.k8s.io
  resources:
    - endpoints
    - endpointslices
    - ingresses
    - nodes
    - nodes/proxy
    - nodes/metrics
    - pods
    - services
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - pods
    - pods/log
    - namespaces
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - monitoring.grafana.com
  resources:
    - podlogs
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - monitoring.coreos.com
  resources:
    - prometheusrules
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
    - /metrics
  verbs:
    - get
- apiGroups:
    - monitoring.coreos.com
  resources:
    - podmonitors
    - servicemonitors
    - probes
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - events
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - configmaps
    - secrets
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - apps
  resources:
    - replicasets
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - extensions
  resources:
    - replicasets
  verbs:
    - get
    - list
    - watch
```
## Grafana Agent Events
```yaml
- apiGroups:
    - ''
    - discovery.k8s.io
    - networking.k8s.io
  resources:
    - endpoints
    - endpointslices
    - ingresses
    - nodes
    - nodes/proxy
    - nodes/metrics
    - pods
    - services
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - pods
    - pods/log
    - namespaces
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - monitoring.grafana.com
  resources:
    - podlogs
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - monitoring.coreos.com
  resources:
    - prometheusrules
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
    - /metrics
  verbs:
    - get
- apiGroups:
    - monitoring.coreos.com
  resources:
    - podmonitors
    - servicemonitors
    - probes
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - events
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - configmaps
    - secrets
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - apps
  resources:
    - replicasets
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - extensions
  resources:
    - replicasets
  verbs:
    - get
    - list
    - watch
```
## Grafana Agent Logs
```yaml
- apiGroups:
    - ''
    - discovery.k8s.io
    - networking.k8s.io
  resources:
    - endpoints
    - endpointslices
    - ingresses
    - nodes
    - nodes/proxy
    - nodes/metrics
    - pods
    - services
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - pods
    - pods/log
    - namespaces
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - monitoring.grafana.com
  resources:
    - podlogs
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - monitoring.coreos.com
  resources:
    - prometheusrules
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
    - /metrics
  verbs:
    - get
- apiGroups:
    - monitoring.coreos.com
  resources:
    - podmonitors
    - servicemonitors
    - probes
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - events
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - configmaps
    - secrets
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - apps
  resources:
    - replicasets
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - extensions
  resources:
    - replicasets
  verbs:
    - get
    - list
    - watch
```
When deploying to an OpenShift cluster, these extra rules are added to enable access to special a SecurityContextConstraint:
```yaml
- verbs:
    - use
  apiGroups:
    - security.openshift.io
  resources:
    - securitycontextconstraints
  resourceNames:
    - k8smon-grafana-agent-logs
```
## Kube State Metrics
```yaml
- apiGroups:
    - certificates.k8s.io
  resources:
    - certificatesigningrequests
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - configmaps
  verbs:
    - list
    - watch
- apiGroups:
    - batch
  resources:
    - cronjobs
  verbs:
    - list
    - watch
- apiGroups:
    - extensions
    - apps
  resources:
    - daemonsets
  verbs:
    - list
    - watch
- apiGroups:
    - extensions
    - apps
  resources:
    - deployments
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - endpoints
  verbs:
    - list
    - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - list
    - watch
- apiGroups:
    - extensions
    - networking.k8s.io
  resources:
    - ingresses
  verbs:
    - list
    - watch
- apiGroups:
    - batch
  resources:
    - jobs
  verbs:
    - list
    - watch
- apiGroups:
    - coordination.k8s.io
  resources:
    - leases
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - limitranges
  verbs:
    - list
    - watch
- apiGroups:
    - admissionregistration.k8s.io
  resources:
    - mutatingwebhookconfigurations
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - namespaces
  verbs:
    - list
    - watch
- apiGroups:
    - networking.k8s.io
  resources:
    - networkpolicies
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - nodes
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - persistentvolumeclaims
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - persistentvolumes
  verbs:
    - list
    - watch
- apiGroups:
    - policy
  resources:
    - poddisruptionbudgets
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - pods
  verbs:
    - list
    - watch
- apiGroups:
    - extensions
    - apps
  resources:
    - replicasets
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - replicationcontrollers
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - resourcequotas
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - secrets
  verbs:
    - list
    - watch
- apiGroups:
    - ''
  resources:
    - services
  verbs:
    - list
    - watch
- apiGroups:
    - apps
  resources:
    - statefulsets
  verbs:
    - list
    - watch
- apiGroups:
    - storage.k8s.io
  resources:
    - storageclasses
  verbs:
    - list
    - watch
- apiGroups:
    - admissionregistration.k8s.io
  resources:
    - validatingwebhookconfigurations
  verbs:
    - list
    - watch
- apiGroups:
    - storage.k8s.io
  resources:
    - volumeattachments
  verbs:
    - list
    - watch
```
## OpenCost
```yaml
- apiGroups:
    - ''
  resources:
    - configmaps
    - deployments
    - nodes
    - pods
    - services
    - resourcequotas
    - replicationcontrollers
    - limitranges
    - persistentvolumeclaims
    - persistentvolumes
    - namespaces
    - endpoints
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - extensions
  resources:
    - daemonsets
    - deployments
    - replicasets
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - apps
  resources:
    - statefulsets
    - deployments
    - daemonsets
    - replicasets
  verbs:
    - list
    - watch
- apiGroups:
    - batch
  resources:
    - cronjobs
    - jobs
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - policy
  resources:
    - poddisruptionbudgets
  verbs:
    - get
    - list
    - watch
- apiGroups:
    - storage.k8s.io
  resources:
    - storageclasses
  verbs:
    - get
    - list
    - watch
```
