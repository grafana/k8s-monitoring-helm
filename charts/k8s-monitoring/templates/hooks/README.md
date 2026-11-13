<!--alex disable hook-->
<!--alex disable hooks-->

# Helm Hooks

This directory contains Helm hooks that ensure proper deployment order and reliability of the k8s-monitoring chart.

## Post Install/Upgrade Hooks

### Add Finalizer

This post-install/post-upgrade hook adds a finalizer to the Alloy Operator Deployment. This ensures that the operator
can not be deleted before the Alloy instances are cleaned up, preventing orphaned resources.

Steps:

1.  Adds a finalizer to the Alloy Operator Deployment

## Pre Delete Hooks

### Remove Alloy and Finalizer

This pre-delete hook requests deletion of the Alloy instances created by this Helm chart, waits for their deletion with
a bounded timeout, and then removes the finalizer from the Alloy Operator Deployment. If Alloy instances remain when the
timeout expires, the hook fails and leaves the operator Deployment finalizer in place so the operator can continue
cleanup.

Steps:

1.  Deletes all Alloy instances created by this Helm chart
2.  Waits up to `alloy-operator.waitForAlloyRemoval.timeoutSeconds` for all Alloy instances to be deleted
3.  Removes the finalizer from the Alloy Operator Deployment

The hook Job has a deadline 60 seconds longer than the Alloy deletion timeout. Configure the deletion timeout below
the Helm or Flux uninstall timeout so the hook can fail with diagnostics before its caller times out.
