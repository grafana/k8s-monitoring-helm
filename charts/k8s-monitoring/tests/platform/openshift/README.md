# OpenShift platform test

Verifies that the `k8s-monitoring` Helm chart deploys and reports correctly on OpenShift. The cluster
runs on Google Cloud (GCP). Unlike the other platform tests, it can't run against the cluster directly
from the CI runner — GCP org policy forces a more involved design, explained below.

## Why it's different

Two org policies on the `grafana-k8s-monitoring` project drive everything:

- `constraints/compute.restrictLoadBalancerCreationForTypes` allows only **internal** load balancers,
  so the cluster must use **`publish: Internal`**. That makes the Kubernetes API **private (VPC-only)**.
- `constraints/compute.vmExternalIpAccess` denies **external IPs on VMs**.

Because the API is private, a GitHub runner / laptop can't drive the install directly. So the
runner/laptop acts only as an **orchestrator**: it creates a short-lived **worker VM inside the VPC**,
and that VM does the real work. Since the VM has no public IP, the orchestrator reaches it over
**IAP-tunneled SSH**.

## How it works

Two scripts, split by where they run:

- **`run-test.sh`** — orchestrator (CI runner / laptop; invoked by `make run-test`). It:
  1. builds a code bundle (repo + `helm-chart-toolbox`, no secrets);
  2. generates the Grafana Cloud Secret manifest (`make all`, client-side);
  3. creates the worker VM (no external IP) in the `default` VPC, us-west1;
  4. over IAP SSH, copies the bundle and streams the GCP key + Grafana Cloud Secret to the VM;
  5. runs `run-on-vm.sh` on the VM;
  6. deletes the VM (always, even on failure).
- **`run-on-vm.sh`** — worker (bundled, runs on the VM). It reads the secrets from `tmpfs`, installs
  tooling (`kubectl`, `helm`, `yq`, `flux`, `kustomize`, `openshift-install`), runs
  `openshift-install create cluster` and `helm-test`, and destroys the cluster on exit.

The cluster installs into the existing `default` VPC/subnet so its private nodes get egress via the
Cloud NAT already there (needed to pull OKD images).

## Infrastructure

Reused (pre-existing — not created by the test):

- `default` VPC + its us-west1 subnet (`10.138.0.0/20`; the cluster's `machineNetwork`).
- Cloud NAT `nat-router-us-west1` (egress for the private nodes and worker VM).
- Cloud DNS zone for `okd.grafana.petewall.net`.
- Firewall `default-allow-ssh` (`tcp:22`), which already covers IAP's range `35.235.240.0/20`.

Created per run (all destroyed at the end): one worker VM (`e2-standard-4`), and one OpenShift cluster
(a control-plane VM, internal load balancers, firewall rules, a private DNS zone, per-component service
accounts, disks; 0 workers).

## Permissions and one-time setup

Everything runs as `k8s-monitoring-helm-cluster-cr@grafana-k8s-monitoring.iam.gserviceaccount.com`
(CI: GitHub OIDC → Vault; local: `.envrc` → 1Password). It already holds the roles the test needs:
`compute.admin`, `dns.admin`, `iam.serviceAccountAdmin`, `iam.securityAdmin`, `storage.admin`, and
`iap.tunnelResourceAccessor` (to SSH the no-public-IP VM). The worker VM itself is created with **no
service account** (`--no-service-account`); `openshift-install` authenticates with the streamed key.

Two one-time, admin-only prerequisites (already in place; documented for reproducing in another project):

1. Enable the IAP API: `gcloud services enable iap.googleapis.com`.
2. Grant IAP tunnel access, scoped to SSH:
   ```
   gcloud projects add-iam-policy-binding grafana-k8s-monitoring \
     --member="serviceAccount:k8s-monitoring-helm-cluster-cr@grafana-k8s-monitoring.iam.gserviceaccount.com" \
     --role="roles/iap.tunnelResourceAccessor" \
     --condition='title=iap-ssh-only,expression=destination.port == 22'
   ```
   A project-level grant is used because the role can't be bound to a VM directly, and the SA already
   has IAM-admin rights, so a per-run grant/revoke would add churn without reducing its real power.

### Secrets

Two secrets reach the VM — the Grafana Cloud credentials and the Google Cloud service-account key. Both are
streamed over the encrypted IAP SSH channel into **`tmpfs` (`/dev/shm`, RAM) only** — never in the
code bundle, on the VM's disk, or in Cloud Storage / metadata / Secret Manager — and are gone when the
VM is deleted. The Grafana Cloud credentials must end up as an in-cluster Secret (that's what the test
exercises, same as every platform test), so the real safeguard is **credential scope**: use a
least-privilege, ideally short-lived Grafana Cloud access-policy token.

## Running the test

Both CI and local use the `make run-test` entrypoint; only credential sourcing differs.

- **CI:** `make -C <test-dir> run-test DIRENV=0` (the `Platform Test` workflow sets `TOOLBOX_DIR` and
  provides credentials via Vault + `google-github-actions/auth`). `DIRENV=0` skips the direnv wrapper.
- **Local:** `make -C charts/k8s-monitoring/tests/platform/openshift run-test`. Requires `gcloud`,
  `git`, `rsync`, `make`, `kubectl`, `direnv`, and the 1Password CLI (`op`) with access to the
  `Kubernetes Monitoring` vault. `run-test` wraps the run in direnv so `.envrc` loads credentials.
  The heavy tooling runs on the VM, not your laptop. Wrap in `caffeinate -is` — if the Mac
  sleeps/locks, the SSH/IAP tunnel drops and the run aborts (CI runners don't sleep).

## Teardown and leftovers

The cluster is destroyed by an EXIT trap in `run-on-vm.sh` (retries until it succeeds); the worker VM
is deleted by the orchestrator's cleanup. Both run on success and failure. As a backstop against a
dead orchestrator, the VM is created with `--max-run-duration=7200s --instance-termination-action=DELETE`,
so GCE auto-deletes it (and its in-RAM key) after 2h regardless. If a run is hard-interrupted and leaks
a cluster, reconstruct its `metadata.json` (from the `infraID` that prefixes the leaked resources, plus
`projectID` + `region`) and run `openshift-install destroy cluster --dir <dir>`; leftover resources are
labeled `kubernetes-io-cluster-<infraID>: owned`. `destroy` never deletes the BYO `default` network.

## Files

| File | Purpose |
|---|---|
| `run-test.sh` | Orchestrator (runs on CI runner / laptop). |
| `run-on-vm.sh` | Worker (bundled; runs on the VM). |
| `Makefile` | `run-test` entrypoint + `all` (builds the Grafana Cloud Secret manifest). |
| `openshift-cluster-config.yaml` | OpenShift install-config: `publish: Internal`, us-west1, BYO `default` network. |
| `test-plan.yaml` | helm-chart-toolbox test plan: cluster type, values, and PromQL/LogQL assertions. |
| `values.yaml` | `k8s-monitoring` chart values. |
| `.envrc` | Local-only: loads GCP + Grafana Cloud credentials from 1Password via direnv. |
