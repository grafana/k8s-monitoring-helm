# Private Data Source Connect (PDC) Integration Test

This test verifies that the Private Data Source Connect (PDC) agent is properly deployed and configured to establish secure connections between Grafana Cloud and private data sources.

## Test Scope

The test validates:
- PDC agent deployment with proper configuration
- Secret creation and management for PDC credentials
- PDC agent connectivity and health status
- Integration with cluster metrics collection
- Self-reporting metrics from the PDC feature

## Test Infrastructure

- **PostgreSQL**: Deployed as a private data source to simulate a real-world scenario
- **Prometheus**: For collecting metrics and validating PDC functionality
- **Test Queries**: Validate PDC agent metrics and cluster connectivity

## Expected Behavior

1. PDC agent should deploy successfully with provided credentials
2. Agent should establish connection to the configured PDC cluster
3. Self-reporting metrics should indicate PDC feature is enabled and operational
4. Private data sources should be accessible through the PDC tunnel

## Validation Queries

The test runs queries to verify:
- PDC agent is running and healthy
- Feature self-reporting metrics are present
- Cluster metrics are being collected alongside PDC functionality 