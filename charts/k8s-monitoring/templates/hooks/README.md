<!--alex disable hook-->
<!--alex disable hooks-->

# Helm Hooks

This directory contains Helm hooks that ensure proper deployment order and reliability of the k8s-monitoring chart.

## Post Install/Upgrade Hooks

### Add Finalizer

This post-install/post-upgrade hook adds a finalizer to the Alloy Operator Deployment. This ensures that the operator
can not be deleted before the Alloy instances are cleaned up, preventing orphaned resources.

Steps:

1. Adds a finalizer to the Alloy Operator Deployment

### Wait for Operator

This post-install/post-upgrade hook ensures that the Alloy Operator is fully ready before any Alloy custom resources are
created. This prevents timing issues where Alloy resources could be created before the operator is available to process
them.

Steps:

1.  Waits for the Alloy Operator deployment to be available
2.  Waits for the Alloy Operator pods to be ready
3.  Times out after 300 seconds if the operator doesn't become ready

This hook addresses the issue where some Alloy custom resources (especially `alloy-singleton`) would not be created
consistently due to timing race conditions between Helm resource creation and the Alloy Operator becoming ready.

## Pre Delete Hooks

### Remove Alloy and Finalizer

This pre-delete hook removes the Alloy instnaces that were created by this Helm chart, it waits for them to be removed,
and then removes the finalizer from the Alloy Operator Deployment. This allows for the Helm chart deletion to proceed.

Steps:

1. Deletes all Alloy instances created by this Helm chart
2. Waits for all Alloy instances to be deleted
3. Adds a finalizer to the Alloy Operator Deployment
