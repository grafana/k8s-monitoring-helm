<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Windows Event Logs

The Windows Event Logs feature enables the collection of event logs from Windows Kubernetes Cluster Nodes. It uses the
[`loki.source.windowsevent`](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.source.windowsevent/)
Alloy component to read from the Windows Event Log channels. Each entry in the `sources` list becomes its own
`loki.source.windowsevent` component. No channels are gathered by default, so you must configure at least one source.

This feature requires a collector running on the Windows Nodes. Use the `windows` and `daemonset` collector presets so
that an Alloy Pod runs as a HostProcess container on every Windows Node.

## Usage

```yaml
windowsEventLogs:
  enabled: true
  collector: alloy-windows
  sources:
    - name: application
      eventLogName: Application
      jobLabel: integrations/windows-application-logs
    - name: system
      eventLogName: System
      jobLabel: integrations/windows-system-logs

collectors:
  alloy-windows:
    presets: [windows, daemonset]
```

([values](#values))

## Sources

The `sources` list controls which event log channels are gathered. Each entry becomes its own
`loki.source.windowsevent` component, so you can gather any channel (`Application`, `System`, `Security`, or a custom
provider channel) without being limited to a hard-coded set. Each entry needs a unique `name` (used for the Alloy
component label and the bookmark file name) and either an `eventLogName` or an [XPath query](https://learn.microsoft.com/en-us/windows/win32/wes/consuming-events)
that specifies the channel in XML form.

```yaml
windowsEventLogs:
  enabled: true
  sources:
    - name: application
      eventLogName: Application
      jobLabel: integrations/windows-application-logs
    - name: system
      eventLogName: System
      jobLabel: integrations/windows-system-logs
      # Only gather Warning (Level=3), Error (Level=2), and Critical (Level=1) events.
      xpathQuery: "*[System[(Level=1 or Level=2 or Level=3)]]"
    # An XML-form query specifies the channel itself, so no eventLogName is required.
    - name: low-memory
      jobLabel: integrations/windows-low-memory
      xpathQuery: "System/*[UserData/LowOnMemory]"
```

## Bookmarks

To avoid re-reading events after a Pod restart, this feature stores a bookmark file for each channel. Because the
collector runs as a DaemonSet, the bookmarks are persisted to a directory on each Windows Node via a `hostPath` volume
mount. You can change the path or disable persistence entirely:

```yaml
windowsEventLogs:
  enabled: true
  bookmarks:
    enabled: true
    hostPath: 'C:\ProgramData\Grafana\Alloy\WindowsEventLogs'
```

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `deployAsConfigMap` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

<!-- textlint-disable terminology -->
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| petewall | <pete.wall@grafana.com> |  |
| TylerHelmuth | <tyler.helmuth@grafana.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-windows-event-logs>
<!-- markdownlint-enable list-marker-space -->

## Values

### Bookmarks

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bookmarks.enabled | bool | `true` | Whether to persist the read position (bookmark) for each event log channel to a directory on the host. This keeps Alloy from re-reading events after a Pod restart. Because the collector runs as a DaemonSet, the bookmarks are stored on each Windows Node via a `hostPath` volume mount. When disabled, Alloy re-reads events from the beginning of each channel when the Pod restarts. |
| bookmarks.hostPath | string | `"C:\\ProgramData\\Grafana\\Alloy\\WindowsEventLogs"` | The path on the Windows Node where bookmark files are stored. |

### Collection settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| excludeEventData | bool | `false` | Whether to exclude the rendered `EventData` from the log message. |
| excludeEventMessage | bool | `false` | Whether to exclude the human-friendly event message from the log message. |
| excludeUserData | bool | `false` | Whether to exclude the rendered `UserData` from the log message. |
| locale | int | `0` | The [locale ID (LCID)](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/) to use when rendering event messages. `0` uses the system default locale. |
| pollInterval | string | `"3s"` | How frequently to poll the event log for new events. |
| useIncomingTimestamp | bool | `false` | Whether to use the event's own creation timestamp as the log timestamp, rather than the time the event was read. |

### Processing settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraLabels | object | `{}` | Log labels to set from extracted event fields. Format: `<label>: <field>`. Available fields include: `channel`, `computer`, `source`, `eventID`, `keywords`, `level`, `levelText`, `opCode`, `task`, `timeCreated`. |
| extraLogProcessingStages | string | `""` | Stage blocks to be added to the loki.process component for event logs. ([docs](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.process/#blocks)) This value is templated so that you can refer to other values from this file. |
| structuredMetadata | object | `{}` | The structured metadata mappings to set. To not set any structured metadata, set this to an empty object (e.g. `{}`) Format: `<key>: <field>`. Available fields include: `channel`, `computer`, `source`, `eventID`, `keywords`, `level`, `levelText`, `opCode`, `task`, `timeCreated`. |

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.namespaceOverride | string | `""` | Override the namespace for namespaced resources created by this chart. |

### Event Log Sources

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| sources | list | `[]` | The list of Windows event log sources to gather. Each entry becomes a separate `loki.source.windowsevent` component, so you can gather any channel (for example `Application`, `System`, or `Security`) without hard-coding a fixed set. Per-entry fields:   - `name` (required): a unique identifier used for the Alloy component label and the bookmark file name.   - `eventLogName`: the Windows event log channel to read from. Required unless `xpathQuery` specifies the channel in     [XML form](https://learn.microsoft.com/en-us/windows/win32/wes/consuming-events).   - `jobLabel`: the value for the `job` label on this source's logs.   - `xpathQuery`: an [XPath query](https://learn.microsoft.com/en-us/windows/win32/wes/consuming-events) for filtering     which events are read. The default of `*` reads all events.   - `labels`: a map of additional static labels to set on this source's logs. |
<!-- markdownlint-enable no-bare-urls -->
