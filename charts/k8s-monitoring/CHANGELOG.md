# Changelog

## Unreleased

## 3.2.6

*   Fix timing issues where Alloy custom resources could be created before the Alloy Operator is ready to process them
*   Add pre-install hook to wait for Alloy Operator readiness before creating Alloy resources
*   Add `alloy-operator.waitForReadiness` configuration option to control the timing behavior

## 3.2.0

*   Prevent Node Exporter from even generating metrics about ramfs and tmpfs (@petewall)
*   New feature: Profiles Receiver (@petewall)
*   Set the `job` label on sources from the Annotation Autodiscovery feature to more reasonable values (@petewall)
*   Set `service.namespace` and `service.instance.id` labels from typical sources when using the Pod Logs feature (@petewall)
