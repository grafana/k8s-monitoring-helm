<!--alex disable hook-->
<!--alex disable hooks-->

# Helm Hooks

This directory contains Helm hooks that ensure proper deployment order and reliability of the k8s-monitoring chart.

## wait-for-operator.yaml

This post-install/post-upgrade hook ensures that the Alloy Operator is fully ready before any Alloy custom resources are
created. This prevents timing issues where Alloy resources could be created before the operator is available to process
them.

### When it runs

-   Post-install: Before the initial deployment
-   Post-upgrade: Before chart upgrades
-   Hook weight: 5 (runs early in the process)

### What it does

1.  Waits for the Alloy Operator deployment to be available
2.  Waits for the Alloy Operator pods to be ready
3.  Times out after 300 seconds if the operator doesn't become ready

### Configuration

-   Controlled by `alloy-operator.waitForReadiness`
-   Only created when `alloy-operator.deploy` is true

This hook addresses the issue where some Alloy custom resources (especially `alloy-singleton`) would not be created
consistently due to timing race conditions between Helm resource creation and the Alloy Operator becoming ready.
