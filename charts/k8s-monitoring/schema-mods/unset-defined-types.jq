# By default, the destinations and integrations look like arrays, but we're going to turn them into references
# to "#/definitions/destination-list" and "#/definitions/integration-list" respectively.
del(.properties.destinations.type) |
del(.properties["alloy-metrics"]) |
del(.properties["alloy-singleton"]) |
del(.properties["alloy-logs"]) |
del(.properties["alloy-receiver"]) |
del(.properties["alloy-profiles"])
