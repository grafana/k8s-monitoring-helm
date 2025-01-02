{{- define "feature.profiling.module" }}
declare "profiling" {
  argument "profiles_destinations" {
    comment = "Must be a list of profile destinations where collected profiles should be forwarded to"
  }

  {{- include "feature.profiling.ebpf.alloy" . | indent 2 }}
  {{- include "feature.profiling.java.alloy" . | indent 2 }}
  {{- include "feature.profiling.pprof.alloy" . | indent 2 }}
}
{{- end -}}

{{- define "feature.profiling.alloyModules" }}{{- end }}
