{{- define "english_list" }}
{{- if eq (len .) 0 }}
{{- else if eq (len .) 1 }}
{{- index . 0 }}
{{- else if eq (len .) 2 }}
{{- index . 0 }} and {{ index . 1 }}
{{- else }}
{{- $last := index . (sub (len .) 1) }}
{{- $rest := slice . 0 (sub (len .) 1) }}
{{- join ", " $rest }}, and {{ $last }}
{{- end }}
{{- end }}
