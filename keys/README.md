# Helm chart signing keys

Public GPG keys used to verify the provenance of signed Helm chart
dependencies with `helm ... --verify --keyring <file>`.

## grafana-helm-charts-pubkey.gpg

The "Grafana Helm Charts" signing key. It verifies chart dependencies pulled
from `https://grafana.github.io/helm-charts`, such as `k8s-manifest-tail`,
`alloy-operator`, and other Grafana charts this chart depends on.

Key fingerprint `DDFB 6E2B E7ED 4FB1 1AA7 24C0 1D7C DC27 7F44 2050`. The key
expires 2028-06-21. Confirm this fingerprint from a trusted, independent
source before you replace the key.
