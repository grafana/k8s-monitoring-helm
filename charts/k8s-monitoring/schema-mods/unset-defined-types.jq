# By default, destinations looks like an array, but we're going to turn it into a reference to "#/definitions/destination-list".
del(.properties.destinations.type) |
del(.properties["alloy-metrics"]) |
del(.properties["alloy-singleton"]) |
del(.properties["alloy-logs"]) |
del(.properties["alloy-receiver"]) |
del(.properties["alloy-profiles"])
