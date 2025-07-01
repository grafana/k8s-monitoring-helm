# Private Data Source Connect (PDC) Integration Test

This test verifies that the Private Data Source Connect (PDC) agent is properly deployed and configured by the k8s-monitoring Helm chart.

## Test Scope

The test validates:
- PDC agent deployment creation with proper configuration
- Secret creation and management for PDC credentials  
- PDC pod creation and basic resource setup
- Chart template integration and rendering
- Kubernetes resource validation

## Test Infrastructure

- **k8s-monitoring-test**: Validates PDC deployment through Prometheus metrics from kube-state-metrics

## Expected Behavior

1. PDC agent deployment should be created successfully with provided credentials
2. PDC secret should be created with the correct structure
3. PDC pod should be created (connectivity to PDC server not tested due to fake credentials)
4. Chart should integrate PDC feature without template errors

## Validation Tests

The test performs:
- PDC deployment existence verification
- PDC secret creation and structure validation  
- PDC pod creation confirmation
- Basic cluster metrics availability

## Note on Connectivity

This test uses fake credentials for PDC configuration, so the agent will not successfully connect to the real PDC service. The test focuses on validating that the chart correctly deploys and configures the PDC resources, not the runtime connectivity to Grafana Cloud. 