{{- define "policy.block" -}}
{{- $policy := . }}

policy {
  name = "{{ $policy.name }}"
  type = "{{ $policy.type }}"

  {{- if eq $policy.type "composite" }}
  composite {
    max_total_spans_per_second = {{ $policy.composite.max_total_spans_per_second }}

    {{- $policyOrderNames := list -}}
    {{- range $sub := $policy.composite.composite_sub_policy }}
      {{- $policyOrderNames = append $policyOrderNames $sub.name -}}
    {{- end }}
    policy_order = [{{ include "policy.quoteAll" $policyOrderNames }}]



    {{- range $sub := $policy.composite.composite_sub_policy }}
    composite_sub_policy {
      name = "{{ $sub.name }}"
      type = "{{ $sub.type }}"
      {{- if eq $sub.type "numeric_attribute" }}
      numeric_attribute {
        key = "{{ $sub.numeric_attribute.key }}"
        min_value = {{ $sub.numeric_attribute.min_value }}
      }
      {{- else if eq $sub.type "string_attribute" }}
      string_attribute {
        key = "{{ $sub.string_attribute.key }}"
        values = [{{ include "policy.quoteAll" $sub.string_attribute.values }}]
      }
      {{- else if eq $sub.type "always_sample" }}
      # No inner config
      {{- end }}
    }
    {{- end }}

    rate_allocation = [
    {{- range $alloc := $policy.composite.rate_allocation }}
      {
        policy = "{{ $alloc.policy }}"
        percent = {{ $alloc.percent }}
      },
    {{- end }}
    ]
  }
  {{- end }}
}
{{- end }}

