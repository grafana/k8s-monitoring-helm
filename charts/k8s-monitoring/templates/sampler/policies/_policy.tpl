{{- define "policy.block" -}}
{{- $policy := . -}}
policy {
  name = {{ $policy.name | quote }}
  type = {{ $policy.type | quote }}
  {{- if and (ne $policy.type "composite") (ne $policy.type "and") }}
{{ include "policy.generate" $policy | trim | indent 2 }}
  {{- else if eq $policy.type "and" }}
  and {
  {{- range $sub := $policy.and.and_sub_policy }}
    and_sub_policy {
      name = {{ $sub.name | quote }}
      type = {{ $sub.type | quote }}
{{ include "policy.generate" $sub | trim | indent 6 }}
    }
  {{- end }}
  }
  {{- else if eq $policy.type "composite" }}
  composite {
    max_total_spans_per_second = {{ $policy.composite.max_total_spans_per_second }}

    {{- $policyOrderNames := list -}}
    {{- range $sub := $policy.composite.composite_sub_policy }}
      {{- $policyOrderNames = append $policyOrderNames $sub.name -}}
    {{- end }}
    policy_order = [{{ include "policy.quoteAll" $policyOrderNames }}]

    {{- range $sub := $policy.composite.composite_sub_policy }}
    composite_sub_policy {
      name = {{ $sub.name | quote }}
      type = {{ $sub.type | quote -}}
      {{- $cp :=  include "policy.generate" $sub | trim }}
      {{- if $cp }}
{{ $cp | indent 6 }}
      {{- end }}
    }
    {{- end }}

    {{- range $alloc := $policy.composite.rate_allocation }}
    rate_allocation {
      policy = {{ $alloc.policy | quote }}
      percent = {{ $alloc.percent }}
    }
    {{- end }}
  }
  {{- end }}
}
{{- end }}
