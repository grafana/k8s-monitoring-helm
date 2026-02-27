{{- define "telemetryServices.validate" }}
  {{- include "telemetryServices.validate.opencost" . }}
{{- end }}

{{- define "telemetryServices.validate.opencost" }}
{{- if .Values.telemetryServices.opencost.deploy }}
  {{- $destinations := include "features.costMetrics.destinations" . | fromYamlArray }}
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
      {{- if eq (len $destinations) 1 }}
      {{- $msg = append $msg (printf "    metricsSource: %s" (first $destinations)) }}
      {{- else }}
      {{- $msg = append $msg "    metricsSource:  <metrics destination name>" }}
      {{- $msg = append $msg (printf "Where <metrics destination name> is one of %s" (include "english_list_or" $destinations)) }}
      {{- end }}
      {{- fail (join "\n" $msg) }}
    {{- end }}

    {{- $destinationFound := false }}
    {{- range $index, $destinationName := $destinations }}
      {{- if eq $destinationName $.Values.telemetryServices.opencost.metricsSource }}
        {{- $destinationFound = true }}
        {{- $destination := include "destination.getDestinationByName" (deepCopy $ | merge (dict "destination" $destinationName )) | fromYaml }}
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
            {{- $destinationSecret := include "secrets.kubernetesSecretName" (dict "Values" $.Values "Chart" $.Chart "Release" $.Release "object" $destination) }}
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
      {{- $msg = append $msg (printf "Where <metrics destination name> is one of %s" (include "english_list_or" $destinations)) }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end -}}
{{- end -}}
