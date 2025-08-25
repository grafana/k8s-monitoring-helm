# Changelog

## Unreleased

## 3.3.2

*   Properly truncate tail sampling and service grapher Alloy instances (@petewall)
*   Add the ability to set the default scrape timeout for Prometheus Operator Objects feature (@petewall)
*   Update OpenCost to 2.2.2 and Prom Operator CRDs to 23.0.0 (@petewall)
*   Adding sys.env functions to remoteConfig collector (@AzgadAGZ)

## 3.3.1

*   Update OpenCost to 2.2 (@petewall)
*   Add Image pull secrets and pull policy to Helm hooks (@petewall)
*   Fix "scrapeProcotols" typo (@SeamusGrafana)
*   Add transform support for spanmetrics (@mbaykara)
*   Fix hook arm64 compatibility and don't fail if Alloy instance already deleted (@petewall)

## 3.3

*   Add passthrough for k8sattributes processor (@patst)
*   Improve Windows Exporter discovery rules (@petewall)
*   Add a pair of hooks to add finalizers and Alloy instance cleanup to prevent orphaned resources (@petewall)
*   Fix timing issues where Alloy custom resources could be created before the Alloy Operator is ready to process them (@AzgadAGZ)
*   Add pre-install hook to wait for Alloy Operator readiness before creating Alloy resources (@AzgadAGZ)
*   Add `alloy-operator.waitForReadiness` configuration option to control the timing behavior (@AzgadAGZ)
*   Allow passing destinations as a map (@thandleman-r7)
*   Allow for modifying alloy settings in one place. (@petewall)
*   add span attribute support for skip metrics generation (@mbaykara)
*   Add kube_cronjob.* to kube-state-metrics default allow lest (@sleepyfoodie)

## 3.2.6

*   Add the ability to set error mode for filter and transform processors (@petewall)
*   Skip beyla generated traces in span metrics (@rlankfo)
*   Upgrade beyla helm chart to 1.9.2 in auto-instrumentation feature chart (@rlankfo)

## 3.2.5

*   Bump kube-state-metrics to 6.1.4 (@petewall)
*   Allow for destination and remoteconfig usernames to be numbers (@petewall)

## 3.2.4

*   Bump beyla, alloy, alloy operator, ksm, prom-operator crds (@petewall)

## 3.2.3

*   Include collector.id in span metrics transform (@rlankfo)
*   Update annotation handling for profilng targets. (@petewall)
*   Bump Windows Exporter to 0.12.1 (@petewall)
*   crd-validation: 🐛 remove bad double quote in crd validation (@jmapro)

## 3.2.2

*   Bump Alloy Operator to 0.3.7 (@petewall)
*   Improve how integration logs and metrics are enabled so they can be properly disabled (@petewall)

## 3.2.1

*   Try a new method for ensuring that there is a newline at the end of the prom file (@petewall)
*   Remove check to prevent deploying if /var/log or /var/lib/docker/containers are set when they may not be needed. (@petewall)
*   Bump Node Exporter to 4.47.3 (@petewall)

## 3.2.0

*   Prevent Node Exporter from even generating metrics about ramfs and tmpfs (@petewall)
*   New feature: Profiles Receiver (@petewall)
*   Set the `job` label on sources from the Annotation Autodiscovery feature to more reasonable values (@petewall)
*   Set `service.namespace` and `service.instance.id` labels from typical sources when using the Pod Logs feature (@petewall)
