{{- /*
Validates that a static or custom namespace job name can be used as an Alloy block label, which only accepts letters,
digits, and underscores. The label is also what the exporter reports as the metrics' `name` label, so rewriting it
here would silently change the labels users query on. Fail instead and let them pick a usable name.
Inputs: name, jobType (string, for error messages), instanceName
*/ -}}
{{- define "feature.cloudwatchMetrics.validate.jobName" }}
{{- if not (regexMatch "^[A-Za-z_][A-Za-z0-9_]*$" .name) }}
  {{- $msg := list "" (printf "The %s in cloudwatchMetrics instance %q has the name %q, which Alloy cannot use." .jobType (.instanceName | toString) .name) }}
  {{- $msg = append $msg "This name becomes an Alloy block label, so it may only contain letters, digits, and" }}
  {{- $msg = append $msg "underscores, and may not start with a digit. It is also reported as the metrics' \"name\" label." }}
  {{- $msg = append $msg (printf "Try %q instead." (regexReplaceAll "[^A-Za-z0-9_]" .name "_")) }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- end }}

{{- /*
Validates the jobs shared by all three job types: every job needs at least one region to query and at least one
metric to gather, and any role it assumes needs an ARN.
Inputs: job, jobType (string, for error messages), instanceName, regions (instance default), roles (instance default)
*/ -}}
{{- define "feature.cloudwatchMetrics.validate.job" }}
{{- $job := .job }}
{{- $where := printf "%s in cloudwatchMetrics instance %q" .jobType (.instanceName | toString) }}
{{- if not ($job.regions | default .regions) }}
  {{- $msg := list "" (printf "A %s has no regions to query." $where) }}
  {{- $msg = append $msg "Set the regions on the job, or set instance-level regions used by every job:" }}
  {{- $msg = append $msg "cloudwatchMetrics:" }}
  {{- $msg = append $msg "  instances:" }}
  {{- $msg = append $msg (printf "    - name: %s" (.instanceName | toString)) }}
  {{- $msg = append $msg "      regions: [eu-central-1]" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- if not $job.metrics }}
  {{- $msg := list "" (printf "A %s has no metrics." $where) }}
  {{- $msg = append $msg "The CloudWatch exporter requires at least one metric per job. For example:" }}
  {{- $msg = append $msg "metrics:" }}
  {{- $msg = append $msg "  - name: CPUUtilization" }}
  {{- $msg = append $msg "    statistics: [Average]" }}
  {{- fail (join "\n" $msg) }}
{{- end }}
{{- range $metric := $job.metrics }}
  {{- if not $metric.name }}
    {{- fail (printf "\nA metric on a %s is missing a name." $where) }}
  {{- end }}
  {{- if not $metric.statistics }}
    {{- $msg := list "" (printf "The metric %q on a %s has no statistics." $metric.name $where) }}
    {{- $msg = append $msg "Set the CloudWatch statistics to gather, for example: statistics: [Average, Maximum]" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
{{- end }}
{{- range $role := ($job.roles | default .roles) }}
  {{- if not $role.roleArn }}
    {{- fail (printf "\nA role on a %s is missing a roleArn." $where) }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "feature.cloudwatchMetrics.validate" }}
{{- $names := list }}
{{- range $index, $instance := .Values.instances }}
  {{- if not $instance.name }}
    {{- $msg := list "" (printf "The cloudwatchMetrics instance at position %d has no name." (add $index 1)) }}
    {{- $msg = append $msg "Every instance needs a name, which is used as the metrics' instance label:" }}
    {{- $msg = append $msg "cloudwatchMetrics:" }}
    {{- $msg = append $msg "  instances:" }}
    {{- $msg = append $msg "    - name: my-aws-account" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- /* Instance names become Alloy component labels, so two instances that differ only in punctuation would
         generate colliding components. Compare the normalized names to catch that. */ -}}
  {{- $alloyName := include "helper.alloy_name" $instance.name }}
  {{- if has $alloyName $names }}
    {{- $msg := list "" (printf "More than one cloudwatchMetrics instance resolves to the name %q." $alloyName) }}
    {{- $msg = append $msg "Instance names must be unique, and are compared with \"-\", \" \", and \"_\" treated as equal." }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
  {{- $names = append $names $alloyName }}

  {{- $jobContext := dict "instanceName" $instance.name "regions" ($instance.regions | default list) "roles" ($instance.roles | default list) }}

  {{- /* sts_region is a required argument on the exporter, and defaults to the first configured region. */ -}}
  {{- if not (or $instance.stsRegion $instance.regions) }}
    {{- $msg := list "" (printf "The cloudwatchMetrics instance %q has neither regions nor an stsRegion." $instance.name) }}
    {{- $msg = append $msg "The CloudWatch exporter needs a region to call STS in. Set the regions to query:" }}
    {{- $msg = append $msg "cloudwatchMetrics:" }}
    {{- $msg = append $msg "  instances:" }}
    {{- $msg = append $msg (printf "    - name: %s" $instance.name) }}
    {{- $msg = append $msg "      regions: [eu-central-1]" }}
    {{- $msg = append $msg "Or set stsRegion explicitly when each job sets its own regions." }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- $jobCount := add (len ($instance.discoveryJobs | default list)) (len ($instance.staticJobs | default list)) (len ($instance.customNamespaceJobs | default list)) }}
  {{- if eq $jobCount 0 }}
    {{- $msg := list "" (printf "The cloudwatchMetrics instance %q has no jobs." $instance.name) }}
    {{- $msg = append $msg "Add at least one discoveryJobs, staticJobs, or customNamespaceJobs entry, otherwise the" }}
    {{- $msg = append $msg "exporter gathers nothing. For example:" }}
    {{- $msg = append $msg "cloudwatchMetrics:" }}
    {{- $msg = append $msg "  instances:" }}
    {{- $msg = append $msg (printf "    - name: %s" $instance.name) }}
    {{- $msg = append $msg "      regions: [eu-central-1]" }}
    {{- $msg = append $msg "      discoveryJobs:" }}
    {{- $msg = append $msg "        - type: AWS/SQS" }}
    {{- $msg = append $msg "          metrics:" }}
    {{- $msg = append $msg "            - name: NumberOfMessagesSent" }}
    {{- $msg = append $msg "              statistics: [Sum]" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- range $job := ($instance.discoveryJobs | default list) }}
    {{- if not $job.type }}
      {{- $msg := list "" (printf "A discoveryJobs entry in cloudwatchMetrics instance %q has no type." $instance.name) }}
      {{- $msg = append $msg "Set the CloudWatch service to discover, for example: type: AWS/EC2" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
    {{- include "feature.cloudwatchMetrics.validate.job" (merge (dict "job" $job "jobType" "discoveryJobs entry") $jobContext) }}
  {{- end }}

  {{- range $job := ($instance.staticJobs | default list) }}
    {{- if not $job.name }}
      {{- fail (printf "\nA staticJobs entry in cloudwatchMetrics instance %q has no name. The name becomes the metrics' name label." $instance.name) }}
    {{- end }}
    {{- include "feature.cloudwatchMetrics.validate.jobName" (dict "name" $job.name "jobType" "staticJobs entry" "instanceName" $instance.name) }}
    {{- if not $job.namespace }}
      {{- $msg := list "" (printf "The staticJobs entry %q in cloudwatchMetrics instance %q has no namespace." $job.name $instance.name) }}
      {{- $msg = append $msg "Set the CloudWatch namespace to query, for example: namespace: AWS/EC2" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
    {{- if not $job.dimensions }}
      {{- $msg := list "" (printf "The staticJobs entry %q in cloudwatchMetrics instance %q has no dimensions." $job.name $instance.name) }}
      {{- $msg = append $msg "A static job does not use discovery, so it needs the dimensions naming the resource:" }}
      {{- $msg = append $msg "dimensions:" }}
      {{- $msg = append $msg "  InstanceId: i-0123456789abcdef0" }}
      {{- $msg = append $msg "To discover resources by tag instead, use discoveryJobs." }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
    {{- include "feature.cloudwatchMetrics.validate.job" (merge (dict "job" $job "jobType" (printf "staticJobs entry %q" $job.name)) $jobContext) }}
  {{- end }}

  {{- range $job := ($instance.customNamespaceJobs | default list) }}
    {{- if not $job.name }}
      {{- fail (printf "\nA customNamespaceJobs entry in cloudwatchMetrics instance %q has no name. The name becomes the metrics' name label." $instance.name) }}
    {{- end }}
    {{- include "feature.cloudwatchMetrics.validate.jobName" (dict "name" $job.name "jobType" "customNamespaceJobs entry" "instanceName" $instance.name) }}
    {{- if not $job.namespace }}
      {{- $msg := list "" (printf "The customNamespaceJobs entry %q in cloudwatchMetrics instance %q has no namespace." $job.name $instance.name) }}
      {{- $msg = append $msg "Set the custom CloudWatch namespace to query, for example: namespace: MyApplication" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
    {{- include "feature.cloudwatchMetrics.validate.job" (merge (dict "job" $job "jobType" (printf "customNamespaceJobs entry %q" $job.name)) $jobContext) }}
  {{- end }}

  {{- range $role := ($instance.roles | default list) }}
    {{- if not $role.roleArn }}
      {{- fail (printf "\nA role on the cloudwatchMetrics instance %q is missing a roleArn." $instance.name) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
