# By default, the destinations and integrations look like arrays, but we're going to turn them into references
# to "#/definitions/destination-list" and "#/definitions/integration-list" respectively.
del(.properties.integrations.type) | del(.properties.destinations.type)
