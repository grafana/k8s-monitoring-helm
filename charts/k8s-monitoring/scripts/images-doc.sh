#!/usr/bin/env bash

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chartDir="$(dirname "${scriptDir}")"

releaseName="k8smon"
helmVersion="$(yq eval '.version' "${chartDir}/Chart.yaml")"

# Images pulled directly from the Alloy Helm chart (Alloy Operator's AppVersion is the Alloy version)
alloyOperatorVersion="$(yq eval '.dependencies[] | select(.name=="alloy-operator") | .version' "${chartDir}/Chart.yaml")"
alloyHelmVersion="$(helm show chart "${chartDir}/charts/alloy-operator-${alloyOperatorVersion}.tgz" | yq eval '.appVersion')"
alloyImage="$(         helm template test --repo https://grafana.github.io/helm-charts alloy --version "${alloyHelmVersion}" | yq eval 'select(.kind=="DaemonSet" and .metadata.name=="test-alloy") | .spec.template.spec.containers[0].image')"
configReloaderImage="$(helm template test --repo https://grafana.github.io/helm-charts alloy --version "${alloyHelmVersion}" | yq eval 'select(.kind=="DaemonSet" and .metadata.name=="test-alloy") | .spec.template.spec.containers[1].image')"

# Images pulled from rendered output of the example manifests
clusterMetricsOutputFile="${chartDir}/docs/examples/features/cluster-metrics/default/output.yaml"
beylaMetricsOutputFile="${chartDir}/docs/examples/features/auto-instrumentation/beyla-metrics/output.yaml"

alloyOperatorImage="$( yq eval "select(.kind==\"Deployment\" and .metadata.name==\"${releaseName}-alloy-operator\")     | .spec.template.spec.containers[0].image" "${clusterMetricsOutputFile}")"
beylaImage="$(         yq eval "select(.kind==\"DaemonSet\"  and .metadata.name==\"${releaseName}-beyla\")              | .spec.template.spec.containers[0].image" "${beylaMetricsOutputFile}")"
keplerImage="$(        yq eval "select(.kind==\"DaemonSet\"  and .metadata.name==\"${releaseName}-kepler\")             | .spec.template.spec.containers[0].image" "${clusterMetricsOutputFile}")"
ksmImage="$(           yq eval "select(.kind==\"Deployment\" and .metadata.name==\"${releaseName}-kube-state-metrics\") | .spec.template.spec.containers[0].image" "${clusterMetricsOutputFile}")"
kubectlImage="$(       yq eval "select(.kind==\"Job\"        and .metadata.name==\"${releaseName}-k8s-monitoring-wait-alloy-operator\") | .spec.template.spec.containers[0].image" "${clusterMetricsOutputFile}")"
nodeExporterImage=$(   yq eval "select(.kind==\"DaemonSet\"  and .metadata.name==\"${releaseName}-node-exporter\")      | .spec.template.spec.containers[0].image" "${clusterMetricsOutputFile}")
opencostImage=$(       yq eval "select(.kind==\"Deployment\" and .metadata.name==\"${releaseName}-opencost\")           | .spec.template.spec.containers[0].image" "${clusterMetricsOutputFile}")
windowsExporterImage=$(yq eval "select(.kind==\"DaemonSet\"  and .metadata.name==\"${releaseName}-windows-exporter\")   | .spec.template.spec.containers[0].image" "${clusterMetricsOutputFile}")

cat << EOF
## Images

The following is the list of images used in the ${helmVersion} version of the Kubernetes Monitoring Helm chart.

### Alloy

The telemetry data collector. Deployed by the Alloy Operator.

**Image**: \`${alloyImage}\`

**Deploy**: \`alloy-____.enabled=true\`

### Alloy Operator

Deploys and manages Grafana Alloy collector instances.

**Image**: \`${alloyOperatorImage}\`

**Deploy**: \`alloy-operator.deploy=true\`

### Beyla

Performs zero-code instrumentation of applications on the Cluster, generating metrics and traces.

**Image**: \`${beylaImage}\`

**Deploy**: \`autoInstrumentation.beyla.enabled=true\`

### Config Reloader

Sidecar for Alloy instances that reloads the Alloy configuration upon changes.

**Image**: \`${configReloaderImage}\`

**Deploy**: \`alloy-____.configReloader.enabled=true\`

### Kepler

**Image**: \`${keplerImage}\`

**Deploy**: \`clusterMetrics.kepler.enabled=true\`

### kube-state-metrics

Gathers Kubernetes Cluster object metrics.

**Image**: \`${ksmImage}\`

**Deploy**: \`clusterMetrics.kube-state-metrics.deploy=true\`

### kubectl

Used for Helm hooks for properly sequencing the Alloy Operator deployment and removal.

**Image**: \`${kubectlImage}\`

**Deploy**: \`alloy-operator.waitForAlloyRemoval.enabled=true\`

### Node Exporter

Gathers Kubernetes Cluster Node metrics for Linux nodes.

**Image**: \`${nodeExporterImage}\`

**Deploy**: \`clusterMetrics.node-exporter.deploy=true\`

### OpenCost

Gathers cost metrics for Kubernetes objects.

**Image**: \`${opencostImage}\`

**Deploy**: \`clusterMetrics.opencost.enabled=true\`

### Windows Exporter

Gathers Kubernetes Cluster Node metrics for Windows nodes.

**Image**: \`${windowsExporterImage}\`

**Deploy**: \`clusterMetrics.windows-exporter.deploy=true\`
EOF
