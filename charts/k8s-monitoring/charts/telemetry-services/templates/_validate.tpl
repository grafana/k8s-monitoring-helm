{{- define "telemetryServices.validate" }}
  {{- include "telemetryServices.validate.opencost" . }}
  {{- include "telemetryServices.validate.nodeExporter" . }}
  {{- include "telemetryServices.validate.beyla" . }}
  {{- include "telemetryServices.validate.sdkInjector" . }}
{{- end }}

{{/*
Validates the SDK Injector telemetry service.

The SDK Injector only accepts injection ConfigMaps written by usernames in its allowlist
(sdkInjector.allowedConfigMapWriters). If it is deployed with an empty allowlist, no collector can
write the ConfigMaps it needs, so require the allowlist to be set and suggest the ServiceAccount of
each enabled collector.
*/}}
{{- define "telemetryServices.validate.sdkInjector" }}
{{- if .Values.telemetryServices.sdkInjector.deploy }}
  {{- if eq .Values.telemetryServices.sdkInjector.allowedConfigMapWriters "" }}
    {{- $writers := list }}
    {{- range $collectorName := include "collectors.list.enabled" . | fromYamlArray }}
      {{- $collectorContext := dict "Values" $.Values "Files" $.Files "Release" $.Release "Chart" $.Chart "collectorName" $collectorName }}
      {{- $serviceAccountName := include "collector.alloy.serviceAccountName" $collectorContext }}
      {{- $writers = append $writers (printf "system:serviceaccount:$(POD_NAMESPACE):%s" $serviceAccountName) }}
    {{- end }}
    {{- $msg := list "" "The SDK Injector requires an allowlist of usernames permitted to create or update annotated injection ConfigMaps." }}
    {{- $msg = append $msg "Please set telemetryServices.sdkInjector.allowedConfigMapWriters to one or more (comma-separated) usernames." }}
    {{- $msg = append $msg "" }}
    {{- if $writers }}
      {{- $msg = append $msg "For the currently enabled collectors, use:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  sdkInjector:" }}
      {{- $msg = append $msg (printf "    allowedConfigMapWriters: %s" (join "," $writers)) }}
    {{- else }}
      {{- $msg = append $msg "For each collector, add its ServiceAccount:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  sdkInjector:" }}
      {{- $msg = append $msg "    allowedConfigMapWriters: system:serviceaccount:$(POD_NAMESPACE):<release-name>-<collector-name>" }}
    {{- end }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Validates the bundled Beyla telemetry service.

For now, the Beyla subchart under telemetryServices is only meant to deploy the standalone Kubernetes metadata
cache (k8sCache), not Beyla itself. Beyla should be deployed by the Auto-Instrumentation feature.
This check:
  1. Blocks enabling the Beyla agent here (telemetryServices.beyla.enabled), pointing users at the
     autoInstrumentation feature instead.
  2. Prevents deploying two k8sCache instances when both this service and an enabled autoInstrumentation
     feature would each create one.
*/}}
{{- define "telemetryServices.validate.beyla" }}
{{- if .Values.telemetryServices.beyla.deploy }}
  {{- if .Values.telemetryServices.beyla.enabled }}
    {{- $msg := list "" "Deploying the Beyla agent via telemetryServices.beyla.enabled is not supported." }}
    {{- $msg = append $msg "The telemetryServices Beyla service only deploys the standalone Kubernetes metadata cache (k8sCache)." }}
    {{- $msg = append $msg "" }}
    {{- $msg = append $msg "To deploy the Beyla agent, enable the Auto-Instrumentation feature instead:" }}
    {{- $msg = append $msg "autoInstrumentation:" }}
    {{- $msg = append $msg "  enabled: true" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- $cacheReplicas := .Values.telemetryServices.beyla.k8sCache.replicas | int }}
  {{- if (gt $cacheReplicas 0) }}
    {{- $autoInstrumentationEnabled := .Values.autoInstrumentation.enabled }}
    {{- $autoInstrumentationCacheReplicas := dig "beyla" "k8sCache" "replicas" 0 .Values.autoInstrumentation | int }}
    {{- if and ($autoInstrumentationEnabled) (gt $autoInstrumentationCacheReplicas 0) }}
      {{- $msg := list "" "Two Beyla instances are configured to deploy their Kubernetes metadata caches." }}
      {{- $msg = append $msg "The Auto-Instrumentation feature already deploys a k8sCache, so the telemetryServices one is redundant." }}
      {{- $msg = append $msg "" }}
      {{- $msg = append $msg "Please turn off the telemetryServices Beyla cache:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  beyla:" }}
      {{- $msg = append $msg "    deploy: false" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Best-effort check for an existing Node Exporter when deploying the bundled one.
Uses `lookup` to find DaemonSets that look like Node Exporter and bind the same port. `lookup` returns
nothing during `helm template`/`--dry-run` (no cluster connection), so this check is skipped in those cases.
If a conflict is found, recommend either using the existing Node Exporter or deploying on a unique port.
*/}}
{{- define "telemetryServices.validate.nodeExporter" }}
{{- $nodeExporter := index .Values.telemetryServices "node-exporter" }}
{{- if and $nodeExporter.deploy (dig "portConflictCheck" true $nodeExporter) }}
  {{- $ourPort := dig "service" "port" 9100 $nodeExporter | int }}
  {{- $conflict := dict }}
  {{- range $daemonSet := (lookup "apps/v1" "DaemonSet" "" "").items }}
    {{- if not $conflict.found }}
      {{- $labels := $daemonSet.metadata.labels | default dict }}
      {{- /* Skip the Node Exporter managed by this release (relevant on upgrades) */}}
      {{- if ne (dig "app.kubernetes.io/instance" "" $labels) $.Release.Name }}
        {{- $nameLabel := dig "app.kubernetes.io/name" "" $labels }}
        {{- $dsHostNetwork := dig "spec" "template" "spec" "hostNetwork" false $daemonSet }}
        {{- $isNodeExporter := regexMatch "node[-_]exporter" $nameLabel }}
        {{- range $container := (dig "spec" "template" "spec" "containers" (list) $daemonSet) }}
          {{- if regexMatch "node[-_]exporter" (dig "image" "" $container) }}
            {{- $isNodeExporter = true }}
          {{- end }}
        {{- end }}
        {{- if $isNodeExporter }}
          {{- range $container := (dig "spec" "template" "spec" "containers" (list) $daemonSet) }}
            {{- range $port := (dig "ports" (list) $container) }}
              {{- if or (eq (int (dig "hostPort" 0 $port)) $ourPort) (and $dsHostNetwork (eq (int (dig "containerPort" 0 $port)) $ourPort)) }}
                {{- $_ := set $conflict "found" true }}
                {{- $_ := set $conflict "namespace" $daemonSet.metadata.namespace }}
                {{- $_ := set $conflict "name" $daemonSet.metadata.name }}
                {{- $_ := set $conflict "nameLabel" (default "prometheus-node-exporter" $nameLabel) }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $conflict.found }}
    {{- $msg := list "" (printf "A Node Exporter already appears to be running in this cluster on port %d." $ourPort) }}
    {{- $msg = append $msg (printf "Found DaemonSet \"%s\" in namespace \"%s\"." $conflict.name $conflict.namespace) }}
    {{- $msg = append $msg "Deploying another Node Exporter on the same port will cause a host port conflict, since Node Exporter runs with hostNetwork enabled." }}
    {{- $msg = append $msg "" }}
    {{- $msg = append $msg "Option 1: Don't deploy the bundled Node Exporter and use the existing one:" }}
    {{- $msg = append $msg "telemetryServices:" }}
    {{- $msg = append $msg "  node-exporter:" }}
    {{- $msg = append $msg "    deploy: false" }}
    {{- if dig "linuxHosts" "enabled" false (.Values.hostMetrics | default dict) }}
      {{- $msg = append $msg "And point Host Metrics at the existing Node Exporter:" }}
      {{- $msg = append $msg "hostMetrics:" }}
      {{- $msg = append $msg "  linuxHosts:" }}
      {{- $msg = append $msg (printf "    namespace: %s" $conflict.namespace) }}
      {{- $msg = append $msg "    labelMatchers:" }}
      {{- $msg = append $msg (printf "      app.kubernetes.io/name: %s" $conflict.nameLabel) }}
    {{- end }}
    {{- $msg = append $msg "" }}
    {{- $msg = append $msg "Option 2: Deploy the bundled Node Exporter on a different, unused port:" }}
    {{- $msg = append $msg "telemetryServices:" }}
    {{- $msg = append $msg "  node-exporter:" }}
    {{- $msg = append $msg "    service:" }}
    {{- $msg = append $msg "      port: <unique-port>" }}
    {{- $msg = append $msg "" }}
    {{- $msg = append $msg "If this detection is incorrect, you can disable this check:" }}
    {{- $msg = append $msg "telemetryServices:" }}
    {{- $msg = append $msg "  node-exporter:" }}
    {{- $msg = append $msg "    portConflictCheck: false" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "telemetryServices.validate.opencost" }}
{{- if .Values.telemetryServices.opencost.deploy }}
  {{- $featureDestinations := include "features.costMetrics.destinations" . | fromYamlArray }}

  {{/*
  The chart mounts an emptyDir at /var/configs (OpenCost's default CONFIG_PATH) so the GCP provider
  can write gcp.json on GKE. When cloud integration is enabled, the OpenCost chart already mounts its
  own writable volume at /var/configs, so our extra mount collides (duplicate mountPath). In that case
  the chart-managed volume is unnecessary and must be removed.
  */}}
  {{- $cloudIntegration := or (dig "opencost" "cloudIntegrationSecret" "" .Values.telemetryServices.opencost) (dig "opencost" "cloudIntegrationJSON" "" .Values.telemetryServices.opencost) }}
  {{- if $cloudIntegration }}
    {{- $varConfigsMount := false }}
    {{- range $mount := (dig "opencost" "exporter" "extraVolumeMounts" (list) .Values.telemetryServices.opencost) }}
      {{- if eq (dig "mountPath" "" $mount) "/var/configs" }}
        {{- $varConfigsMount = true }}
      {{- end }}
    {{- end }}
    {{- if $varConfigsMount }}
      {{- $msg := list "" "OpenCost cloud integration is enabled, which mounts a writable volume at /var/configs." }}
      {{- $msg = append $msg "This conflicts with the chart-managed /var/configs volume used to work around the GKE GCP provider." }}
      {{- $msg = append $msg "Since cloud integration already makes /var/configs writable, remove the chart-managed volume:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- $msg = append $msg "    extraVolumes: []" }}
      {{- $msg = append $msg "    opencost:" }}
      {{- $msg = append $msg "      exporter:" }}
      {{- $msg = append $msg "        extraVolumeMounts: []" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}

  {{- if ne .Values.cluster.name .Values.telemetryServices.opencost.opencost.exporter.defaultClusterId }}
    {{- $msg := list "" "The OpenCost default cluster id should match the cluster name." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "telemetryServices:" }}
    {{- $msg = append $msg "  opencost:" }}
    {{- $msg = append $msg "    opencost:" }}
    {{- $msg = append $msg "      exporter:" }}
    {{- $msg = append $msg (printf "        defaultClusterId: %s" .Values.cluster.name) }}
    {{- fail (join "\n" $msg) }}
  {{- end -}}

  {{- if ne .Values.telemetryServices.opencost.metricsSource "custom" }}
    {{- if eq .Values.telemetryServices.opencost.metricsSource "" }}
      {{- $msg := list "" "OpenCost requires linking to a Prometheus data source." }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- if eq (len $featureDestinations) 1 }}
      {{- $msg = append $msg (printf "    metricsSource: %s" (first $featureDestinations)) }}
      {{- else }}
      {{- $msg = append $msg "    metricsSource:  <metrics destination name>" }}
      {{- $msg = append $msg (printf "Where <metrics destination name> is one of %s" (include "english_list_or" $featureDestinations)) }}
      {{- end }}
      {{- $msg = append $msg "" }}
      {{- $msg = append $msg "Or, to configure OpenCost's metrics source yourself and skip this guided setup, set:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- $msg = append $msg "    metricsSource: custom" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- $destinationFound := false }}
    {{- range $index, $destinationName := $featureDestinations }}
      {{- if eq $destinationName $.Values.telemetryServices.opencost.metricsSource }}
        {{- $destinationFound = true }}
        {{- $destination := get $.Values.destinations $destinationName }}
        {{- $openCostMetricsUrl := (printf "<Query URL for destination \"%s\">" $destinationName) }}
        {{- if $destination.url }}
          {{- if regexMatch "/api/prom/push" $destination.url }}
            {{- $openCostMetricsUrl = (regexReplaceAll "^(.*)/api/prom/push$" $destination.url "${1}/api/prom") }}
          {{- else if regexMatch "/api/v1/push" $destination.url }}
            {{- $openCostMetricsUrl = (regexReplaceAll "^(.*)/api/v1/push$" $destination.url "${1}/api/v1/query") }}
          {{- else if regexMatch "/api/v1/write" $destination.url }}
            {{- $openCostMetricsUrl = (regexReplaceAll "^(.*)/api/v1/write$" $destination.url "${1}/api/v1/query") }}
          {{- end }}
        {{- end }}

        {{- if eq $.Values.telemetryServices.opencost.opencost.prometheus.external.url ""}}
          {{- $msg := list "" "OpenCost requires a url to a Prometheus data source." }}
          {{- $msg = append $msg "Please set:" }}
          {{- $msg = append $msg "telemetryServices:" }}
          {{- $msg = append $msg "  opencost:" }}
          {{- $msg = append $msg "    opencost:" }}
          {{- $msg = append $msg "      prometheus:" }}
          {{- $msg = append $msg "        external:" }}
          {{- $msg = append $msg (printf "          url: %s" $openCostMetricsUrl) }}
          {{- $msg = append $msg "" }}
          {{- $msg = append $msg "Or, to configure OpenCost's metrics source yourself and skip this guided setup, set:" }}
          {{- $msg = append $msg "telemetryServices:" }}
          {{- $msg = append $msg "  opencost:" }}
          {{- $msg = append $msg "    metricsSource: custom" }}
          {{- fail (join "\n" $msg) }}
        {{- end }}

        {{- $authType := include "secrets.authType" $destination }}
        {{- $secretType := include "secrets.secretType" $destination }}
        {{- if eq $authType "basic" }}
          {{- if eq $secretType "embedded" }}
            {{- $destinationUsername := include "secrets.getSecretValue" (dict "object" $destination "key" ".auth.username") }}
            {{- if ne $.Values.telemetryServices.opencost.opencost.prometheus.username $destinationUsername}}
              {{- $msg := list "" (printf "The username for %s and OpenCost do not match." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "telemetryServices:" }}
              {{- $msg = append $msg "  opencost:" }}
              {{- $msg = append $msg "    opencost:" }}
              {{- $msg = append $msg "      prometheus:" }}
              {{- $msg = append $msg (printf "        username: %s" $destinationUsername) }}
              {{- fail (join "\n" $msg) }}
            {{- end }}

            {{- $destinationPassword := include "secrets.getSecretValue" (dict "object" $destination "key" ".auth.password") }}
            {{- if ne $.Values.telemetryServices.opencost.opencost.prometheus.password_key $destinationPassword}}
              {{- $msg := list "" (printf "The password for %s and OpenCost do not match." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "telemetryServices:" }}
              {{- $msg = append $msg "  opencost:" }}
              {{- $msg = append $msg "    opencost:" }}
              {{- $msg = append $msg "      prometheus:" }}
              {{- $msg = append $msg (printf "        password: %s" $destinationPassword) }}
              {{- fail (join "\n" $msg) }}
            {{- end }}
          {{- else }}
            {{- $destinationSecret := include "secrets.kubernetesSecretName" (dict "Values" $.Values "Chart" $.Chart "Release" $.Release "object" $destination "name" $destinationName) }}
            {{- if ne $.Values.telemetryServices.opencost.opencost.prometheus.existingSecretName $destinationSecret}}
              {{- $msg := list "" (printf "OpenCost requires the secret for %s to be set." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "telemetryServices:" }}
              {{- $msg = append $msg "  opencost:" }}
              {{- $msg = append $msg "    opencost:" }}
              {{- $msg = append $msg "      prometheus:" }}
              {{- $msg = append $msg (printf "        existingSecretName: %s" $destinationSecret) }}
              {{- fail (join "\n" $msg) }}
            {{- end }}

            {{- $destinationUsernameKey := include "secrets.getSecretKey" (dict "object" $destination "key" ".auth.username") }}
            {{- if ne $.Values.telemetryServices.opencost.opencost.prometheus.username_key $destinationUsernameKey}}
              {{- $msg := list "" (printf "The username secret key for %s and OpenCost do not match." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "telemetryServices:" }}
              {{- $msg = append $msg "  opencost:" }}
              {{- $msg = append $msg "    opencost:" }}
              {{- $msg = append $msg "      prometheus:" }}
              {{- $msg = append $msg (printf "        username_key: %s" $destinationUsernameKey) }}
              {{- fail (join "\n" $msg) }}
            {{- end }}

            {{- $destinationPasswordKey := include "secrets.getSecretKey" (dict "object" $destination "key" ".auth.password") }}
            {{- if ne $.Values.telemetryServices.opencost.opencost.prometheus.password_key $destinationPasswordKey}}
              {{- $msg := list "" (printf "The password secret key for %s and OpenCost do not match." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "telemetryServices:" }}
              {{- $msg = append $msg "  opencost:" }}
              {{- $msg = append $msg "    opencost:" }}
              {{- $msg = append $msg "      prometheus:" }}
              {{- $msg = append $msg (printf "        password_key: %s" $destinationPasswordKey) }}
              {{- fail (join "\n" $msg) }}
            {{- end }}
          {{- end }}
        {{- else if ne $authType "none" }}
          {{- $msg := list "" (printf "Unable to provide guidance for configuring OpenCost to use %s authentication for %s." $authType $destinationName) }}
          {{- $msg = append $msg "Please set:" }}
          {{- $msg = append $msg "telemetryServices:" }}
          {{- $msg = append $msg "  opencost:" }}
          {{- $msg = append $msg "    metricsSource: custom" }}
          {{- $msg = append $msg ("And configure %s authentication for %s using guidance from the OpenCost Helm chart.") }}
          {{- $msg = append $msg "Documentation: https://github.com/opencost/opencost-helm-chart/tree/main/charts/opencost" }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- if eq $destinationFound false }}
      {{- $msg := list "" (printf "The destination \"%s\" is not a Prometheus data source." $.Values.telemetryServices.opencost.metricsSource) }}
      {{- $msg = append $msg "OpenCost requires a Prometheus database to query where cluster metrics are stored." }}
      {{- $msg = append $msg "" }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "telemetryServices:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- $msg = append $msg "    metricsSource:  <metrics destination name>" }}
      {{- $msg = append $msg (printf "Where <metrics destination name> is one of %s" (include "english_list_or" $featureDestinations)) }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
