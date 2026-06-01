# Changelog

## Unreleased

*   Add a best-effort validator that checks (via Helm `lookup`) for an existing Node Exporter using the same port when deploying the bundled `telemetryServices.node-exporter`. If a port conflict is detected, the install fails with guidance to either skip the deployment and point Host Metrics at the existing Node Exporter, or deploy on a unique port. (@petewall)

## 4.1.4

*   Fix the Service Integrations feature silently rendering no integration modules when `integrations.collector` was left at its default empty string. The feature now relies on the same collector resolution as every other feature, so simply enabling integrations (e.g. `integrations.alloy`, `integrations.cert-manager`, `integrations.istio`) generates the expected Alloy modules without also having to set `integrations.collector` explicitly (#2625) (@petewall)
*   Add `timeout` setting on the OTLP destination (@petewall)
*   Fail rendering with a clear error when `profiling.enabled: true` is set but none of `profiling.ebpf.enabled`, `profiling.java.enabled`, or `profiling.pprof.enabled` are enabled, instead of silently producing a profiling feature that collects no data (#2620) (@petewall)
*   Fix Alloy collector instances cross-contaminating each other's `mounts.extra` (and other nested values from `collectorCommon.alloy` or per-instance `collectors.<name>`) due to Sprig `mergeOverwrite` aliasing nested map/slice references. The user-supplied merge inputs (`$userCommonValues` and `$userValues`) are now `deepCopy`-ed before merging (#2623) (@petewall)
*   Update Alloy Operator to 0.5.8, OpenCost to 2.5.21 and Windows Exporter to 0.12.7 (@petewall)

## 4.1.3

*   Add support for the write-ahead log (WAL) setting on the Loki destination (@nooboo)
*   Add `drop` policy support for tail sampling (@petewall)
*   Add global pull policy support for the hooks and collectors (@petewall)
*   Fix `spanMetrics.excludeDimensions` rendering: list values are now properly quoted as strings instead of unquoted bareword identifiers, which caused Alloy to fail to parse the rendered config. (#2596) (@savannahostrowski)
*   Remove scrape protocols from the four `prometheus.operator.*` components, which do not support setting them. (@MattiasSegerdahl)

## 4.1.2

*   Add convertClassicHistogramsToNhcb setting to global (@MattiasSegerdahl)
*   Update Beyla to 1.16.7 (@petewall)
*   Fix `global.scrapeNativeHistograms: true` crash-looping the alloy-metrics collector with `scrape_native_histograms is set to true, but PrometheusProto is not in scrape_protocols`. The chart now automatically prepends `PrometheusProto` to the rendered `scrape_protocols` list whenever native histograms are enabled, so the single-knob migration from chart 3.5.x works without also overriding `global.scrapeProtocols` (#2582) (@petewall)
*   Fix custom destinations with `traces.enabled: true` or `profiles.enabled: true` failing to render with `nil pointer evaluating interface {}.target`. The traces and profiles `target` template lookups now read from the correct template context (`.destination.traces.target` / `.destination.profiles.target`) so the configured target is forwarded into the rendered Alloy config (#2590) (@petewall)

## 4.1.1

*   Fix the pre-delete and post-install Alloy-finalizer hook templates failing to render when `alloy-operator.waitForAlloyRemoval.securityContext` is set to `null` (#2569) (@petewall)
*   Update Alloy Operator to 0.5.7, Beyla to 1.16.6, and k8s-manifest-tail to 0.1.4 (@petewall)
*   Fix `extraLogProcessingStages` (and `extraLogProcessingRules` on `podLogsObjects`) failing to render under older Helm versions (e.g. those bundled with the Terraform Helm provider) with `cannot retrieve Template.Basepath from values inside tpl function`, by propagating `Template` through to the feature module includes that call `tpl` (@petewall)
*   Set `opencost.opencost.exporter.cloudProviderApiKey` to `"disabled"` so OpenCost does not try to write `/var/configs/gcp.json` on GCP/GKE and panic. Removes the placeholder GCP API key (and its `trufflehog:ignore` workarounds) from the chart defaults (@petewall)
*   Fix OpenCost crashing on GKE: point `CONFIG_PATH` at `/tmp` so the GCP provider can write its `gcp.json` (the default `/var/configs` is not writable by the non-root container user, which caused a nil-pointer panic). Set `CLOUD_PROVIDER_API_KEY=disabled` so the GCP provider can be constructed without a real billing API key, and remove the placeholder API key (and its `trufflehog:ignore` workarounds) from the chart defaults (@petewall)
*   Add the ability to set `scrapeNativeHistograms` for the Prometheus Operator Objects feature (@lukas-unity)

## 4.1

*   Add `small`, `medium`, `large`, and `xlarge` collector presets that set Alloy resource requests and limits for common cluster sizes (@petewall)
*   Add `global.namespaceOverride` to deploy namespaced resources into a custom namespace across this chart and its feature subcharts (@petewall)
*   Add the ability to replace the contents of an Alloy component (@petewall)
*   Add the ability to set the cluster name using arbitrary sources with `cluster.nameFrom` (@petewall)
*   Add `clusterEvents.clustering` to allow Cluster Events to run on a clustered collector with multiple replicas, sharding event collection across peers (@petewall)
*   Database Observability: emit proper relabeling for MySQL and PostgreSQL so both metrics and logs carry `job=integrations/db-o11y`, the configured `instance` name,
    and a `dsn` label for Knowledge Graph integration. Breaking change for users on `databaseObservability.enabled: true`: the default `job` label is now `integrations/db-o11y`
    (was `integration/mysql` for MySQL and `integration/postgresql` for PostgreSQL), and the `instance` label on db o11y logs is the instance name (was the raw DSN, which now lives on the `dsn` label) (@cristiangreco)
*   Database Observability: add `databaseObservability.cloudProvider.gcp` for MySQL and PostgreSQL to label metrics with GCP Cloud SQL instance metadata (@cristiangreco)
*   Database Observability: add `databaseObservability.collectors.querySamples.sampleMinDuration` and `waitEventMinDuration` for MySQL (@cristiangreco)
*   Database Observability: emit `disable_collectors` for any MySQL or PostgreSQL collector explicitly turned off via `databaseObservability.collectors.<name>.enabled: false` (@cristiangreco)
*   Database Observability: realign some default `databaseObservability.collectors` values with Alloy upstream defaults (@cristiangreco)
*   Database Observability: remove the unused `databaseObservability.collectors.explainPlans.excludeSchemas` value from the PostgreSQL settings (@cristiangreco)
*   Add the ability to capture Kubernetes Manifests as log data (@petewall)

## 4.0.5

*   Add the ability to set per-signal paths for OTLP/http destinations (@petewall)
*   Update Node Exporter to 4.55.0 (@petewall)

## 4.0.4

*   Set Prometheus destination cluster labels via `external_labels` instead of `write_relabel_config` blocks, matching the Loki destination pattern (@petewall)
*   Fix Loki, Mimir, and Grafana integrations spamming `failed to decode logfmt` errors for non-logfmt components like the Loki/Mimir gateway (nginx) and canary, by gating the logfmt parser on lines that look like logfmt (#1726) (@petewall)
*   Set `appProtocol` on the OTLP, Zipkin, and Jaeger HTTP/gRPC ports registered by the Application Observability feature, and pass `appProtocol` from `collectors.<name>.alloy.extraPorts` through to the optional receiver Service, so Istio sidecars reliably pick the right L7 filter instead of falling back to protocol sniffing (@petewall)
*   Update Alloy Operator to 0.5.6 and kube-state-metrics to 7.3.0 (@petewall)
*   Change Alloy collector `labels` and `annotations` defaults from arrays to maps, and accept either type in the schema for backwards compatibility (@petewall)
*   Warn in NOTES.txt when installing into an Istio-enabled namespace with Alloy clustering using the default "http" port name, which breaks clustering peer discovery and causes duplicate metrics (@petewall)
*   PostgreSQL: Add `statementsLimit` option to the Database Observability `queryDetails` collector (@petewall)
*   Normalize collector and destination names to DNS-1123 resource names so mixed-case or underscore-containing keys (e.g. `alloyMetrics`, `my_dest`) render valid Kubernetes resources, and fail when two keys collapse to the same normalized name (@petewall)

## 4.0.3

*   Add `enabled` flag to collectors so they can be disabled without removing them from the values file (@petewall)
*   Update Alloy Operator, Beyla, Node Exporter and OpenCost (@petewall)
*   Add validators to require clustering on collectors that are assigned cluster-enabled features (@petewall)
*   Add validators to warn when deployment-level settings are placed under feature configs instead of telemetryServices (@petewall)
*   Fix validation error messages referencing `labelSelectors` instead of the correct `labelMatchers` field (@petewall)

## 4.0.2

*   Switch from deprecated Endpoints discovery to EndpointSlice for Kubernetes 1.33+ compatibility (@petewall)
*   Fix node log level parsing broken since v4.0 due to case mismatch in selectors (@petewall)
*   Use glob syntax instead of regular expressions in Beyla discovery config (@petewall)

## 4.0.1

*   Remove extra `/var/configs` volume mount from OpenCost (@petewall)
*   Add node labels to  host metrics feature (@petewall)
*   Update Alloy Operator, Beyla, Node Exporter, and Windows Exporter (@petewall)
*   Fix serviceGraphMetrics routing metrics to the wrong OTLP destination when multiple destinations are defined (@petewall)
*   Fix pre-delete hook failing when the finalizer is not present (@petewall)
*   Remove /var/configs volume from OpenCost which could cause problems (@petewall)

## 4.0.0

*   Add Loki thanos metrics to the default allowList (@kinolaev)
*   Rebuild log features to remove `labelsToKeep` and split Loki and OpenTelemetry log gathering (@petewall)
*   Introducce `collectors` as map, and remove named Alloy instances (@petewall)
*   Convert destinations into a map (@petewall)
*   Remove Prometheus Operator Object CRDs (@petewall)
*   Extract supplemental telemetry services from config features into their own subchart (@petewall)

## 3.8.5

*   Update Beyla, Node Exporter, OpenCost, and Prometheus Operator CRDs. (@petewall)
*   Fix Application Observability failing to start when only traces are enabled and metrics are disabled. (@petewall)

## 3.8.4

*   Update Alloy Operator to 1.5.2 (@petewall)
*   Update options for secretFilters in Pod logs features to match changes in Alloy (@petewall)
*   Fix `tls_config` block name to `tls` in `otelcol.auth.oauth2` for OTLP destinations (@petewall)

## 3.8.3

*   Disable the OpenCost MCP server (@petewall)
*   Update Alloy Operator to 1.5.1 (@petewall)
*   PostgreSQL: stat_statements exclude_databases/exclude_users/limit options (@cristiangreco)
*   Add more settings for profiling features (@petewall)

## 3.8.2

*   Find Pod logs for static pods using the config.mirror annotation (@sebastian-de)
*   Add label selectors plus a completed Job filter to the Istio integration sidecar scraper and wire namespace/label selectors for Istiod discovery (@petewall)
*   Fix cAdvisor `includeNamespaces` filter dropping non-namespaced metrics like `machine_*` (@petewall)
*   Update Beyla auto-instrumentation config to use `instrument`/`exclude_instrument`, replacing the deprecated `services`/`exclude_services` (@petewall)
*   Update Beyla to 1.13.0 (@petewall)
*   MySQL: Add perf_schema.eventsstatements collector options (@cristiangreco)
*   Fix: preserve user extraEnv in service graph collector (@rafix)
*   Updated Node Exporter, OpenCost, and Alloy Operator (@petewall)
*   Add TLS configuration support for OAuth2 token endpoints across all destinations (@petewall)
*   Update database_observability setup for Alloy 1.13.x features (@cristiangreco)

## 3.8.1

*   Add an option to set the semantic convention version for Application Observability span names (@petewall)
*   Fix Java profiling so annotation targeting no longer scrapes unannotated pods (@petewall)
*   Fix PSQL integration includeQuery config camel_case (@Dissonant-Tech)

## 3.8.0

*   Add the ability to enrich metrics with pod or namespace labels (@petewall)
*   Set CRI as default logs processor if runtime is unset (@aleksanderaleksic)
*   Add the ability to set protobufMessage and a shortcut for the remote_write protocol (@petewall)
*   Automatically set required environment variables when enabling remote config (@petewall)
*   Add a feature for gathering logs using PodLogs objects (@petewall)
*   Update Windows Exporter to 0.12.3 (@petewall)
*   Update Beyla to 1.11.0 (@petewall)
*   Update Prometheus Operator Object CRDs to 26.0.1 (@petewall)

## 3.7.5

*   Add Configuration to specify the `overrides` Section of the Span Logs Connector Component for the Application Observability Chart (@SeamusGrafana)
*   Update Alloy Operator to 0.4.1 (@petewall)

## 3.7.4

*   Improve OTLP destination protocol validation (@petewall)
*   Update Prometheus Operator Object CRDs (@petewall)
*   Fix Indentation Issues for Beyla Relabel (@SeamusGrafana)
*   Add erofs to node-exporter filesystem exclusions (@tyuchx)

## 3.7.3

*   Update Node Exporter (@petewall)
*   Make the loki.process CRI stage maxPartialLines configurable (@ptodev)
*   Add eBPF sample rate for profiling (@jo030225)
*   Add the ability to skip cluster metrics ServiceMonitor checks (@petewall)

## 3.7.2

*   Update Node Exporter and Alloy Operator (@petewall)
*   Add cloudProvider configuration support to MySQL and Postgresql databaseObservability (@matthewnolf)

## 3.7.1

*   Update Node Exporter and kube-state-metrics (@petewall)
*   Fix MySQL and PostgreSQL integrations for missing log destinations and secrets. (@petewall)

## 3.7.0

*   Deploy beyla-k8s-cache with 1 replica by default in auto-instrumentation feature chart (@skl)
*   Update Alloy Operator and Beyla (@petewall)
*   Add an integration for Istio sidecar and service metrics (@petewall)
*   Add an integration for PostgreSQL, including support for Database Observability (@petewall)
*   Add the ability to set otel_annotations flag for the k8sattributes processor (@petewall)
*   Add more options to the secretFilter component in the pod logs features (@petewall)
*   Check for the presence of kube-state-metrics or Node Exporter ServiceMonitors if clusterMetrics and
    prometheusOperatorObjects features are enabled (@petewall)

## 3.6.2

*   Fix extra quotes for the sending queue storage in OTLP destinations (@petewall)
*   Fix the inclusion of the destination secret for Service Graph instance (@petewall)
*   Update Alloy Operator to 0.3.14 (@petewall)

## 3.6.1

*   Add the ability to override the security context for the waitForAlloyRemoval Helm Hook (@petewall)
*   Add the ability to define the sending queue for OTLP destinations (@petewall)
*   Add the ability to define the remote timeout for Loki destinations (@petewall)

## 3.6.0

*   Add Pod Init container metrics to the kube-state-metrics allow list (@petewall)
*   Add Database Observability to the MySQL integration (@petewall)
*   Add the ability to disable sending traces from Beyla to the Application Observability feature (@marctc & @mbaykara)
*   Add the ability to use ScrapeConfig objects with the Prometheus Operator Objects feature (@petewall)
*   Update opencost to include an emptydir volume mount for its config path (@petewall)

## 3.5.7

*   Update kube-state-metrics and prometheus-operator-crds (@petewall)
*   Add the ability to set `scrape_native_histograms` for Prometheus scrape configs (@SeamusGrafana)
*   Fix port assignment on the etcd integration and several cluster metrics control plane services (@petewall)
*   Fix MySQL integration (@petewall)

## 3.5.6

*   Add the ability to set resources for the Helm hooks (@petewall)
*   Add the ability to set K8s Attribute Processor filters (@petewall)
*   Bump Alloy Operator and Node Exporter (@petewall)

## 3.5.5

*   Set node label for Tempo service integration (@petewall)
*   Update Beyla chart to 1.9.9 (@petewall)

## 3.5.4

*   Update Alloy Operator and Prometheus Operator CRDs (@petewall)
*   Update Beyla and OpenCost (@petewall)
*   Ensure Jaeger Compact and Jeager Thrift protocols use UDP (@simonswine)
*   Ensure Service Graph utilizes destination defaults (@petewall)
*   Update default Service Graph dimensions (@rlankfo)
*   Properly check for integration scrape intervals and timeouts inside the metrics object (@petewall)
*   Set node label for certain service integrations (@petewall)

## 3.5.3

*   Update Alloy Operator, Beyla, OpenCost, and Prometheus Operator CRDs (@petewall)
*   Make Alloy Profiles deployable on all nodes (@petewall)
*   Add label selectors for the Pod Logs feature (@petewall)
*   Add Labels and Annotations to Alloy CR instances (@petewall)

## 3.5.2

*   Add the ability to change pod associations (@petewall)

## 3.5.1

*   Bump prometheus-node-exporter from 4.47.3 to 4.48.0 (@petewall)
*   Add the ability to set the mysql protocol (@petewall)
*   Fix OpenCost validation when using destinationsMap (@petewall)

## 3.5.0

*   Create a separate feature for Pod Logs via Kubernetes API (@petewall)
*   Update default resource attributes remove list (@rlankfo)
*   Span metrics: spans prefilter for internal (@rlankfo)
*   Update the labels set for profiling feature (@petewall)
*   Add Custom type destinations (@petewall)
*   Add the ability to set scrape timeout everywhere (@petewall)

## 3.4.1

*   Update kube-state-metrics and OpenCost (@petewall)
*   Fix the `excludeNamespaces` option in the Prometheus Operator Object feature (@petewall)
*   Add the ability to set labels and annotations on the hook pod (@petewall)
*   Update Node Exporter filesystem exclusion list (@petewall)

## 3.4.0

*   Properly truncate tail sampling and service grapher Alloy instances (@petewall)
*   Remove the "wait for alloy operator" hook (@petewall)
*   Add default attribute remove list support for otlp dest (@mbaykara)
*   Add the ability to override attributes and set tls settings for remote config (@petewall)

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
