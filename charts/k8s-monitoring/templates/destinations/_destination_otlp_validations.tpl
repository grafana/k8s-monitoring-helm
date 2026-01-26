{{- /* Does some basic destination validation */}}
{{- /* Inputs: Values (Values) Destination (an OTLP Destination */}}
{{- define "destinations.otlp.validate" }}
  {{- /* Check if OTLP destination has a valid protocol set */}}
  {{- if (not (has (.Destination.protocol | default "grpc") (list "grpc" "http"))) }}
    {{- $msg := list "" (printf "Destination #%d (%s) has an unsupported protocol: %s." .DestinationIndex .Destination.name .Destination.protocol) }}
    {{- $msg = append $msg "The protocol must be either \"grpc\" or \"http\"" }}
    {{- $msg = append $msg "Please set:" }}
    {{- $msg = append $msg "destinations:" }}
    {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
    {{- $msg = append $msg "    type: otlp" }}
    {{- $msg = append $msg "    protocol: otlp / http" }}
    {{ fail (join "\n" $msg) }}
  {{- end }}

  {{- if and .Destination.proxyURL (eq (.Destination.protocol | default "grpc") "grpc") }}
    {{- $msg := list "" (printf "Destination #%d (%s) does not support proxyURL." .DestinationIndex .Destination.name) }}
    {{- $msg = append $msg "When using the gPRC protocol, the proxyURL option is not supported." }}
    {{- $msg = append $msg "Please remove the proxyURL field and set the appropriate environment variables on the Alloy instances." }}
    {{- $msg = append $msg "Or, change to use the http protocol:" }}
    {{- $msg = append $msg "destinations:" }}
    {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
    {{- $msg = append $msg "    type: otlp" }}
    {{- $msg = append $msg "    protocol: http" }}
    {{- $msg = append $msg "For more information, see https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/examples/proxies" }}
    {{ fail (join "\n" $msg) }}
  {{- end }}

  {{- if .Destination.url }}
    {{- $appearsToBeTempo := regexMatch "tempo-[^.]+\\.grafana\\.net" .Destination.url }}
    {{- $appearsToBeOTLPGateway := regexMatch "otlp-gateway-[^.]+\\.grafana\\.net" .Destination.url }}
    {{- if (dig "protocolValidation" true .Destination) }}
      {{- /* Check if OTLP destination using Grafana Cloud OTLP Gateway uses the right protocol */}}
      {{- if and $appearsToBeOTLPGateway (ne .Destination.protocol "http") }}
        {{- $msg := list "" (printf "Destination #%d (%s) is using Grafana Cloud OTLP gateway but has incorrect protocol '%s'. The gateway requires 'http'." .DestinationIndex .Destination.name (.Destination.protocol | default "grpc (default)")) }}
        {{- $msg = append $msg "Please set:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg (printf "    url: %s" .Destination.url) }}
        {{- $msg = append $msg "    protocol: http" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}

      {{- /* Check if OTLP destination using Grafana Cloud Tempo uses the right protocol */}}
      {{- if and $appearsToBeTempo (ne (.Destination.protocol | default "grpc") "grpc") }}
        {{- $msg := list "" (printf "Destination #%d (%s) is using Grafana Cloud Traces but has incorrect protocol '%s'. Grafana Cloud Traces requires 'grpc'." .DestinationIndex .Destination.name (.Destination.protocol | default "grpc (default)")) }}
        {{- $msg = append $msg "Please set:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg (printf "    url: %s" .Destination.url) }}
        {{- $msg = append $msg "    protocol: grpc" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
    {{- end }}

    {{- /* Check if OTLP destination using Grafana Cloud Tempo uses the right data types */}}
    {{- if $appearsToBeTempo }}
      {{- if eq (dig "metrics" "enabled" true .Destination) true }}
        {{- $msg := list "" (printf "Destination #%d (%s) is using Grafana Cloud Traces but has metrics enabled. Tempo only supports traces." .DestinationIndex .Destination.name) }}
        {{- $msg = append $msg "Please set:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg (printf "    url: %s" .Destination.url) }}
        {{- $msg = append $msg "    metrics:" }}
        {{- $msg = append $msg "      enabled: false" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
      {{- if eq (dig "logs" "enabled" true .Destination) true }}
        {{- $msg := list "" (printf "Destination #%d (%s) is using Grafana Cloud Traces but has logs enabled. Tempo only supports traces." .DestinationIndex .Destination.name) }}
        {{- $msg = append $msg "Please set:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg (printf "    url: %s" .Destination.url) }}
        {{- $msg = append $msg "    logs:" }}
        {{- $msg = append $msg "      enabled: false" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
      {{- if eq (dig "traces" "enabled" true .Destination) false }}
        {{- $msg := list "" (printf "Destination #%d (%s) is using Grafana Cloud Traces but has traces disabled." .DestinationIndex .Destination.name) }}
        {{- $msg = append $msg "Please set:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg (printf "    url: %s" .Destination.url) }}
        {{- $msg = append $msg "    traces:" }}
        {{- $msg = append $msg "      enabled: true" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Sending queue validations */}}
  {{- if eq (dig "sendingQueue" "enabled" true .Destination) true }}
    {{- if eq (dig "sendingQueue" "batch" "enabled" false .Destination) true }}
      {{- if not .Destination.sendingQueue.batch.sizer }}
        {{- $msg := list "" (printf "Destination #%d (%s) is missing a required field." .DestinationIndex .Destination.name) }}
        {{- $msg = append $msg "When using the batch for the sending queue, the sizer is required." }}
        {{- $msg = append $msg "Please set the sizer to \"bytes\" or \"items\":" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg "    sendingQueue:" }}
        {{- $msg = append $msg "      batch:" }}
        {{- $msg = append $msg "        sizer: [bytes, items]" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
      {{- if and (ne .Destination.sendingQueue.batch.sizer "bytes") (ne .Destination.sendingQueue.batch.sizer "items") }}
        {{- $msg := list "" (printf "Destination #%d (%s) has an invalid configuration." .DestinationIndex .Destination.name) }}
        {{- $msg = append $msg "Please set the sizer to \"bytes\" or \"items\":" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg "    sendingQueue:" }}
        {{- $msg = append $msg "      batch:" }}
        {{- $msg = append $msg "        sizer: [bytes, items]" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
      {{- if not .Destination.sendingQueue.batch.flushTimeout }}
        {{- $msg := list "" (printf "Destination #%d (%s) is missing a required field." .DestinationIndex .Destination.name) }}
        {{- $msg = append $msg "When using the batch for the sending queue, the flushTimeout is required." }}
        {{- $msg = append $msg "Please set the flushTimeout to a valid duration:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg "    sendingQueue:" }}
        {{- $msg = append $msg "      batch:" }}
        {{- $msg = append $msg "        flushTimeout: <duration>" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
      {{- if not .Destination.sendingQueue.batch.minSize }}
        {{- $msg := list "" (printf "Destination #%d (%s) is missing a required field." .DestinationIndex .Destination.name) }}
        {{- $msg = append $msg "When using the batch for the sending queue, the minSize is required." }}
        {{- $msg = append $msg "Please set the minSize to a valid amount:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg "    sendingQueue:" }}
        {{- $msg = append $msg "      batch:" }}
        {{- $msg = append $msg "        minSize: <integer>" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
      {{- if not .Destination.sendingQueue.batch.maxSize }}
        {{- $msg := list "" (printf "Destination #%d (%s) is missing a required field." .DestinationIndex .Destination.name) }}
        {{- $msg = append $msg "When using the batch for the sending queue, the maxSize is required." }}
        {{- $msg = append $msg "Please set the maxSize to a valid amount:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg "    sendingQueue:" }}
        {{- $msg = append $msg "      batch:" }}
        {{- $msg = append $msg (printf "        minSize: %d" (.Destination.sendingQueue.batch.minSize | int)) }}
        {{- $msg = append $msg "        maxSize: <integer>" }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
      {{- if ge .Destination.sendingQueue.batch.minSize .Destination.sendingQueue.batch.maxSize }}
        {{- $msg := list "" (printf "Destination #%d (%s) has an invalid configuration." .DestinationIndex .Destination.name) }}
        {{- $msg = append $msg "When using the batch for the sending queue, the minSize must be less than the maxSize." }}
        {{- $msg = append $msg "Please choose different values for the the minSize and maxSize:" }}
        {{- $msg = append $msg "destinations:" }}
        {{- $msg = append $msg (printf "  - name: %s" .Destination.name) }}
        {{- $msg = append $msg "    type: otlp" }}
        {{- $msg = append $msg "    sendingQueue:" }}
        {{- $msg = append $msg "      batch:" }}
        {{- $msg = append $msg (printf "        minSize: %d" (.Destination.sendingQueue.batch.minSize | int)) }}
        {{- $msg = append $msg (printf "        maxSize: %d  # <-- This must be larger than minSize" (.Destination.sendingQueue.batch.maxSize | int)) }}
        {{ fail (join "\n" $msg) }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* TODO: Add validation for catching if traces.enabled = false and processors.tailSampling.enabled = true */}}
{{- end }}
