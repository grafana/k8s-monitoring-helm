<!--alex disable hook-->
<!--alex disable hooks-->

# Helm Hooks

This directory contains Helm hooks that ensure proper deployment order and reliability of the k8s-monitoring chart.

## Pre Install/Upgrade Hooks

### Validate Configuration

This pre-install/pre-upgrade hook validates each enabled collector's generated Alloy config before any chart resources
are applied. For every enabled collector it creates a hook-annotated `ConfigMap` containing the rendered `config.alloy`
(byte-identical to the config the collector will run) and a `Pod` that runs the Alloy image. The pod runs `alloy fmt`
and then `alloy run` against the config; the install or upgrade is aborted on any syntax or load error.

The pod is invoked with `KUBERNETES_SERVICE_HOST` and `KUBERNETES_SERVICE_PORT` deliberately blanked so that Alloy
exits with a well-known error string after the config has been successfully loaded. Any other error indicates an
invalid config.

This hook is opt-in. Enable it with `configValidator.enabled: true`. The validator image and pod settings
(`configValidator.image`, `podLabels`, `podAnnotations`, `securityContext`, `resources`, `nodeSelector`,
`tolerations`, `serviceAccount`, `extraArgs`) can be set explicitly, mirroring the Alloy Operator hooks. When the
image is not set, it defaults to the per-collector Alloy image, then to the Alloy version pinned by this chart's
Alloy Operator. Alloy's storage path is kept on a writable `emptyDir`, so a restrictive `securityContext` (for
example `readOnlyRootFilesystem: true`) still works.

Steps:

1.  Renders one `ConfigMap` and one `Pod` per enabled collector with the `pre-install,pre-upgrade` hook annotations.
2.  Pod runs `alloy fmt` on the rendered config, then `alloy run` with `KUBERNETES_SERVICE_*` blanked, expecting the
    known sentinel error string.
3.  Any other failure aborts the install or upgrade before normal chart resources are applied.

## Post Install/Upgrade Hooks

### Add Finalizer

This post-install/post-upgrade hook adds a finalizer to the Alloy Operator Deployment. This ensures that the operator
can not be deleted before the Alloy instances are cleaned up, preventing orphaned resources.

Steps:

1.  Adds a finalizer to the Alloy Operator Deployment

## Pre Delete Hooks

### Remove Alloy and Finalizer

This pre-delete hook removes the Alloy instnaces that were created by this Helm chart, it waits for them to be removed,
and then removes the finalizer from the Alloy Operator Deployment. This allows for the Helm chart deletion to proceed.

Steps:

1.  Deletes all Alloy instances created by this Helm chart
2.  Waits for all Alloy instances to be deleted
3.  Adds a finalizer to the Alloy Operator Deployment
