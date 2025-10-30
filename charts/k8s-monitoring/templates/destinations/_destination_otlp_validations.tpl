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

  {{- /* Check if OTLP destination using Grafana Cloud OTLP gateway has protocol set */}}
  {{- if .Destination.url }}
    {{- if and (ne .Destination.protocol "http") (regexMatch "otlp-gateway-.+grafana\\.net" .Destination.url) }}
      {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud OTLP gateway but has incorrect protocol '%s'. The gateway requires 'http'.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    protocol: http" .DestinationIndex .Destination.name (.Destination.protocol | default "grpc (default)") .Destination.name .Destination.url) }}
    {{- end }}

    {{- /* Check if OTLP destination using Grafana Cloud Tempo checks */}}
    {{- if and (regexMatch "tempo-.+grafana\\.net" .Destination.url) }}
      {{- if ne (.Destination.protocol | default "grpc") "grpc" }}
        {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud Traces but has incorrect protocol '%s'. Grafana Cloud Traces requires 'grpc'.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    protocol: grpc" .DestinationIndex .Destination.name .Destination.protocol .Destination.name .Destination.url) }}
      {{- end }}
      {{- if eq (dig "metrics" "enabled" true .Destination) true }}
        {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud Traces but has metrics enabled. Tempo only supports traces.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    metrics:\n      enabled: false" .DestinationIndex .Destination.name .Destination.name .Destination.url) }}
      {{- end }}
      {{- if eq (dig "logs" "enabled" true .Destination) true }}
        {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud Traces but has logs enabled. Tempo only supports traces.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    logs:\n      enabled: false" .DestinationIndex .Destination.name .Destination.name .Destination.url) }}
      {{- end }}
      {{- if eq (dig "traces" "enabled" true .Destination) false }}
        {{ fail (printf "\nDestination #%d (%s) is using Grafana Cloud Traces but has traces disabled.\nPlease set:\ndestinations:\n  - name: %s\n    type: otlp\n    url: %s\n    traces:\n      enabled: true" .DestinationIndex .Destination.name .Destination.name .Destination.url) }}
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
