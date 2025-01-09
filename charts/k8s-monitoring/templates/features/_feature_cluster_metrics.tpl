{{- define "features.clusterMetrics.enabled" }}{{ .Values.clusterMetrics.enabled }}{{- end }}

{{- define "features.clusterMetrics.collectors" }}
{{- if .Values.clusterMetrics.enabled -}}
- {{ .Values.clusterMetrics.collector }}
{{- end }}
{{- end }}

{{- define "features.clusterMetrics.include" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray }}
// Feature: Cluster Metrics
{{- include "feature.clusterMetrics.module" (dict "Values" $.Values.clusterMetrics "Files" $.Subcharts.clusterMetrics.Files "Release" $.Release) }}
cluster_metrics "feature" {
  metrics_destinations = [
    {{ include "destinations.alloy.targets" (dict "destinations" $.Values.destinations "names" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- end -}}
{{- end -}}

{{- define "features.clusterMetrics.destinations" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.clusterMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.clusterMetrics.validate" }}
{{- if .Values.clusterMetrics.enabled -}}
{{- $featureName := "Kubernetes Cluster metrics" }}
{{- $destinations := include "features.clusterMetrics.destinations" . | fromYamlArray }}
{{- include "destinations.validate_destination_list" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "feature" $featureName) }}
{{- range $collector := include "features.clusterMetrics.collectors" . | fromYamlArray }}
  {{- include "collectors.require_collector" (dict "Values" $.Values "name" $collector "feature" $featureName) }}
{{- end -}}

{{- if .Values.clusterMetrics.opencost.enabled}}
  {{- if ne .Values.cluster.name .Values.clusterMetrics.opencost.opencost.exporter.defaultClusterId }}
    {{- $msg := list "" "The OpenCost default cluster id should match the cluster name." }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "clusterMetrics:" }}
    {{- $msg = append $msg "  opencost:" }}
    {{- $msg = append $msg "    opencost:" }}
    {{- $msg = append $msg "      exporter:" }}
    {{- $msg = append $msg (printf "        defaultClusterId: %s" .Values.cluster.name) }}
    {{- fail (join "\n" $msg) }}
  {{- end -}}

  {{- if ne .Values.clusterMetrics.opencost.metricsSource "custom" }}
    {{- if eq .Values.clusterMetrics.opencost.metricsSource "" }}
      {{- $msg := list "" "OpenCost requires linking to a Prometheus data source." }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "clusterMetrics:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- if eq (len $destinations) 1 }}
      {{- $msg = append $msg (printf "    metricsSource: %s" (first $destinations)) }}
      {{- else }}
      {{- $msg = append $msg "    metricsSource:  <metrics destination name>" }}
      {{- $msg = append $msg (printf "Where <metrics destination name> is one of %s" (include "english_list_or" $destinations)) }}
      {{- end }}
      {{- fail (join "\n" $msg) }}
    {{- end -}}

    {{- $destinationFound := false }}
    {{- range $index, $destinationName := $destinations }}
      {{- if eq $destinationName $.Values.clusterMetrics.opencost.metricsSource }}
        {{- $destinationFound = true }}
        {{- $destination := index $.Values.destinations $index }}
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

        {{- if eq $.Values.clusterMetrics.opencost.opencost.prometheus.external.url ""}}
          {{- $msg := list "" "OpenCost requires a url to a Prometheus data source." }}
          {{- $msg = append $msg "Please set:" }}
          {{- $msg = append $msg "clusterMetrics:" }}
          {{- $msg = append $msg "  opencost:" }}
          {{- $msg = append $msg "    opencost:" }}
          {{- $msg = append $msg "      prometheus:" }}
          {{- $msg = append $msg "        external:" }}
          {{- $msg = append $msg (printf "          url: %s" $openCostMetricsUrl) }}
          {{- fail (join "\n" $msg) }}
        {{- end }}

        {{- $authType := include "secrets.authType" $destination }}
        {{- $secretType := include "secrets.secretType" $destination }}
        {{- if eq $authType "basic" }}
          {{- if eq $secretType "embedded" }}
            {{- $destinationUsername := include "secrets.getSecretValue" (dict "object" $destination "key" ".auth.username") }}
            {{- if ne $.Values.clusterMetrics.opencost.opencost.prometheus.username $destinationUsername}}
              {{- $msg := list "" (printf "The username for %s and OpenCost do not match." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "clusterMetrics:" }}
              {{- $msg = append $msg "  opencost:" }}
              {{- $msg = append $msg "    opencost:" }}
              {{- $msg = append $msg "      prometheus:" }}
              {{- $msg = append $msg (printf "        username: %s" $destinationUsername) }}
              {{- fail (join "\n" $msg) }}
            {{- end }}
  
            {{- $destinationPassword := include "secrets.getSecretValue" (dict "object" $destination "key" ".auth.password") }}
            {{- if ne $.Values.clusterMetrics.opencost.opencost.prometheus.password_key $destinationPassword}}
              {{- $msg := list "" (printf "The password for %s and OpenCost do not match." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "clusterMetrics:" }}
              {{- $msg = append $msg "  opencost:" }}
              {{- $msg = append $msg "    opencost:" }}
              {{- $msg = append $msg "      prometheus:" }}
              {{- $msg = append $msg (printf "        password: %s" $destinationPassword) }}
              {{- fail (join "\n" $msg) }}
            {{- end }}
          {{- else }}
            {{- $destinationSecret := include "secrets.kubernetesSecretName" (dict "Values" $.Values "Chart" $.Chart "Release" $.Release "object" $destination) }}
            {{- if ne $.Values.clusterMetrics.opencost.opencost.prometheus.existingSecretName $destinationSecret}}
              {{- $msg := list "" (printf "OpenCost requires the secret for %s to be set." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "clusterMetrics:" }}
              {{- $msg = append $msg "  opencost:" }}
              {{- $msg = append $msg "    opencost:" }}
              {{- $msg = append $msg "      prometheus:" }}
              {{- $msg = append $msg (printf "        existingSecretName: %s" $destinationSecret) }}
              {{- fail (join "\n" $msg) }}
            {{- end }}
  
            {{- $destinationUsernameKey := include "secrets.getSecretKey" (dict "object" $destination "key" ".auth.username") }}
            {{- if ne $.Values.clusterMetrics.opencost.opencost.prometheus.username_key $destinationUsernameKey}}
              {{- $msg := list "" (printf "The username secret key for %s and OpenCost do not match." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "clusterMetrics:" }}
              {{- $msg = append $msg "  opencost:" }}
              {{- $msg = append $msg "    opencost:" }}
              {{- $msg = append $msg "      prometheus:" }}
              {{- $msg = append $msg (printf "        username_key: %s" $destinationUsernameKey) }}
              {{- fail (join "\n" $msg) }}
            {{- end }}
  
            {{- $destinationPasswordKey := include "secrets.getSecretKey" (dict "object" $destination "key" ".auth.password") }}
            {{- if ne $.Values.clusterMetrics.opencost.opencost.prometheus.password_key $destinationPasswordKey}}
              {{- $msg := list "" (printf "The password secret key for %s and OpenCost do not match." $destinationName) }}
              {{- $msg = append $msg "Please set:" }}
              {{- $msg = append $msg "clusterMetrics:" }}
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
          {{- $msg = append $msg "clusterMetrics:" }}
          {{- $msg = append $msg "  opencost:" }}
          {{- $msg = append $msg "    metricsSource: custom" }}
          {{- $msg = append $msg ("And configure %s authentication for %s using guidance from the OpenCost Helm chart.") }}
          {{- $msg = append $msg "Documentation: https://github.com/opencost/opencost-helm-chart/tree/main/charts/opencost" }}
          {{- fail (join "\n" $msg) }}
        {{- end }}
      {{- end }}
    {{- end -}}

    {{- if eq $destinationFound false }}
      {{- $msg := list "" (printf "The destination \"%s\" is not a Prometheus data source." $.Values.clusterMetrics.opencost.metricsSource) }}
      {{- $msg = append $msg "OpenCost requires a Prometheus database to query where cluster metrics are stored." }}
      {{- $msg = append $msg "" }}
      {{- $msg = append $msg "Please set:" }}
      {{- $msg = append $msg "clusterMetrics:" }}
      {{- $msg = append $msg "  opencost:" }}
      {{- $msg = append $msg "    metricsSource:  <metrics destination name>" }}
      {{- $msg = append $msg (printf "Where <metrics destination name> is one of %s" (include "english_list_or" $destinations)) }}
      {{- fail (join "\n" $msg) }}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
