# Private Data Source Connect (PDC) Agent

The Private Data Source Connect (PDC) agent enables secure connections between Grafana Cloud and private datasources. It allows you to connect your Grafana Cloud instance to in-cluster datasources that are not publicly accessible.

## Configuration

### Basic Configuration

To enable the PDC agent, set `private-datasource-connect.enabled` to `true` and provide the required credentials:

```yaml
private-datasource-connect:
  enabled: true
  credentials:
    createSecret: true
    token: "your-pdc-token"
    hostedGrafanaId: "your-grafana-cloud-instance-id"
    cluster: "your-pdc-cluster-name"
```

### Credentials Management

There are two ways to provide credentials for the PDC agent:

1.  Create a new secret:

```yaml
private-datasource-connect:
  credentials:
    createSecret: true
    token: "your-pdc-token"
    hostedGrafanaId: "your-grafana-cloud-instance-id"
    cluster: "your-pdc-cluster-name"
```

1.  Use an existing secret:

```yaml
private-datasource-connect:
  credentials:
    createSecret: false
    existingSecret: "your-existing-secret-name"
```

The existing secret must contain the following keys:

-   `token`: The PDC agent authentication token
-   `hosted-grafana-id`: Your Grafana Cloud instance ID
-   `cluster`: The PDC cluster name

#### Example Secret Creation

You can create the secret manually using kubectl:

```bash
kubectl create secret generic my-pdc-secret \
  --from-literal="token=your-pdc-token" \
  --from-literal="hosted-grafana-id=your-grafana-cloud-instance-id"" \
  --from-literal="cluster=your-pdc-cluster-name"
```

Or using a YAML manifest:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-pdc-secret
type: Opaque
data:
  token:
  hosted-grafana-id: 
  cluster: 
```

**Note**: The YAML example shows base64-encoded values. The kubectl command with `--from-literal` handles the encoding automatically.

#### Verifying the Secret

After creating the secret, you can verify it contains the correct keys:

```bash
kubectl get secret my-pdc-secret -o jsonpath='{.data}' | jq -r 'keys[]'
```

Or decode a specific value to verify:

```bash
kubectl get secret my-pdc-secret -o jsonpath='{.data.hosted-grafana-id}' | base64 -d
```

### Resource Management

The PDC agent has default resource requests and limits based on recommended values:

```yaml
private-datasource-connect:
  resources:
    requests:
      cpu: 100m
      memory: 512Mi
    limits:
      cpu: 200m
      memory: 1Gi
```

You can adjust these values based on your needs, but we recommend not going below the minimum requirements.

### Advanced Configuration

#### Image Configuration

```yaml
private-datasource-connect:
  image:
    repository: grafana/pdc-agent
    tag: latest
    pullPolicy: IfNotPresent
```

#### Node Selection

```yaml
private-datasource-connect:
  nodeSelector: {}
  tolerations: []
  affinity: {}
```

## Getting Started

1.  Get your PDC credentials from Grafana Cloud:
    -   PDC token
    -   Hosted Grafana ID
    -   PDC cluster name

2.  Create your values file:

```yaml
private-datasource-connect:
  enabled: true
  credentials:
    createSecret: true
    token: "your-pdc-token"
    hostedGrafanaId: "your-grafana-cloud-instance-id"
    cluster: "your-pdc-cluster-name"
```

1.  Install or upgrade your release:

```bash
helm upgrade --install my-release grafana/k8s-monitoring -f values.yaml
```

### Using Values Override (Recommended for Production)

For production deployments, it's recommended to keep sensitive credentials out of values files and use Helm's `--set-string` flags instead:

```bash
helm upgrade --install my-release grafana/k8s-monitoring -f values.yaml \
  --set-string private-datasource-connect.credentials.token="your-real-pdc-token" \
  --set-string private-datasource-connect.credentials.hostedGrafanaId="your-real-grafana-id" \
  --set-string private-datasource-connect.credentials.cluster="your-real-cluster-name"
```

This approach allows you to:

-   Keep the base values.yaml file in version control without sensitive data
-   Pass real credentials securely at deployment time
-   Use different credentials for different environments

## Troubleshooting

1.  Check PDC agent logs:

```bash
kubectl logs -l app.kubernetes.io/name=pdc-agent
```

1.  Verify the secret was created:

```bash
kubectl get secret <release-name>-pdc-agent
```

1.  Common issues:
    -   Invalid credentials: Check your PDC token, Grafana Cloud instance ID, and cluster name
    -   Resource constraints: Ensure the agent has sufficient CPU and memory
    -   Network connectivity: Verify outbound connectivity to Grafana Cloud
