<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# windows-scrapeable.yaml

<!-- textlint-disable terminology -->
## Values

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"initContainers":[{"args":["New-NetFirewallRule","-DisplayName","'alloy'","-Direction","inbound","-Profile","Any","-Action","Allow","-LocalPort","12345","-Protocol","TCP"],"command":["powershell"],"image":"docker.io/grafana/alloy:v1.18.0-windowsservercore-ltsc2022","name":"configure-firewall"}]}` | Opens the Alloy HTTP port (12345) on the Windows Node's host firewall so that other collectors can scrape this Alloy's own metrics. The `windows-host-process` preset runs Alloy on the host network, where the Windows firewall blocks inbound traffic by default, so the port must be opened explicitly. Apply this preset alongside `windows` and `windows-host-process` when another collector scrapes this Alloy. The rule is added by a HostProcess init container (which inherits HostProcess from the Pod, allowing it to modify the host firewall). |
<!-- textlint-enable terminology -->

<!-- textlint-disable terminology -->
```yaml
---
# Windows scrapeable preset

# -- Opens the Alloy HTTP port (12345) on the Windows Node's host firewall so that other collectors can scrape this
# Alloy's own metrics. The `windows-host-process` preset runs Alloy on the host network, where the Windows firewall
# blocks inbound traffic by default, so the port must be opened explicitly. Apply this preset alongside `windows` and
# `windows-host-process` when another collector scrapes this Alloy. The rule is added by a HostProcess init container
# (which inherits HostProcess from the Pod, allowing it to modify the host firewall).
# @section -- Other Values
controller:
  initContainers:
    # The image is set by the Makefile to match the Windows Alloy image.
    - name: configure-firewall
      image: docker.io/grafana/alloy:v1.18.0-windowsservercore-ltsc2022
      command: ["powershell"]
      args: ["New-NetFirewallRule", "-DisplayName", "'alloy'", "-Direction", "inbound", "-Profile", "Any", "-Action", "Allow", "-LocalPort", "12345", "-Protocol", "TCP"]
```
<!-- textlint-enable terminology -->
