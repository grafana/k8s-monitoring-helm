#!/usr/bin/env bash

scriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chartDir="$(dirname "${scriptDir}")"

releaseName="k8smon"

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

# Output the Markdown table
echo "| System | Image | Description | Enabled with | Deployed by |"
echo "|--------|-------|-------------|--------------|-------------|"
echo "| Alloy | \`${alloyImage}\` | Always used. The telemetry data collector. | \`alloy-____.enabled=true\` | Alloy Operator |"
echo "| Alloy Operator | \`${alloyOperatorImage}\` | Always used. Deploys and manages Grafana Alloy collector instances. | \`alloy-operator.deploy=true\` | - |"
echo "| Beyla | \`${beylaImage}\` | Performs zero-code instrumentation of applications on the Cluster, generating metrics and traces. | \`autoInstrumentation.beyla.enabled=true\` | - |"
echo "| Config Reloader | \`${configReloaderImage}\` | Alloy sidecar that reloads the Alloy configuration upon changes. | \`alloy-____.configReloader.enabled=true\` | Alloy Operator |"
echo "| Kepler | \`${keplerImage}\` | Gathers energy metrics for Kubernetes objects. | \`clusterMetrics.kepler.enabled=true\` | - |"
echo "| kube-state-metrics | \`${ksmImage}\` | Gathers Kubernetes Cluster object metrics. | \`clusterMetrics.kube-state-metrics.deploy=true\` | - |"
echo "| kubectl | \`${kubectlImage}\` | Used by Alloy Operator for Helm hooks. | \`alloy-operator.waitForReadiness.enabled=true\` & \`alloy-operator.waitForReadiness.enabled=true\` | Alloy Operator |"
echo "| Node Exporter | \`${nodeExporterImage}\` | Gathers Kubernetes Cluster Node metrics. | \`clusterMetrics.node-exporter.deploy=true\` | - |"
echo "| OpenCost | \`${opencostImage}\` | Gathers cost metrics for Kubernetes objects. | \`clusterMetrics.opencost.enabled=true\` | - |"
echo "| Windows Exporter | \`${windowsExporterImage}\` | Gathers Kubernetes Cluster Node metrics for Windows nodes. | \`clusterMetrics.windows-exporter.deploy=true\` | - |"
