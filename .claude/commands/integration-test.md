---
description: Run an integration test for an example or test directory
argument-hint: <path-to-test-directory e.g. docs/examples/custom-collector-audit-logs/test>
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# Run Integration Test

Run the integration test at `$ARGUMENTS` within the `charts/k8s-monitoring` directory.

## Prerequisites

The test runner is at `/Users/petewall/src/grafana/helm-chart-toolbox/tools/helm-test/helm-test`. Required CLI tools: `kind`, `helm`, `yq`, `kubectl`, `flux`.

## Steps

### Step 1: Validate the test directory

Confirm the test directory exists and contains a `test-plan.yaml`. The path should be relative to `charts/k8s-monitoring/` (e.g. `docs/examples/custom-collector-audit-logs/test` or `tests/integration/cluster-monitoring`).

### Step 2: Run pre-test setup (if needed)

Check if the test directory has a `Makefile`. If so, run:

```
cd <test-directory> && make clean all
```

This handles generated configs (e.g. Kind cluster configs with absolute paths, generated passwords).

### Step 3: Run the test

From the `charts/k8s-monitoring` directory, run:

```
cd charts/k8s-monitoring && DELETE_CLUSTER=false /Users/petewall/src/grafana/helm-chart-toolbox/tools/helm-test/helm-test <test-directory>
```

Use `DELETE_CLUSTER=false` by default so the user can inspect the cluster afterward. Use a 10-minute timeout since cluster creation and deployments take time.

The test runner executes these steps in order:
1. **create-cluster** — Creates a Kind cluster (or other type) per the test plan
2. **deploy-dependencies** — Deploys Loki, Prometheus, Grafana, etc. via Flux HelmReleases
3. **deploy-subject** — Installs the k8s-monitoring Helm chart with the test values
4. **run-tests** — Runs query tests (PromQL/LogQL) to validate the deployment

### Step 4: Report results

Tell the user whether tests passed or failed. If they passed, remind them:
- The cluster is still running (since `DELETE_CLUSTER=false`)
- The kubectl context name (from the test output)
- To delete with: `kind delete cluster --name <cluster-name>`

If tests failed, show the relevant error output and help debug.
