#!/usr/bin/env bash
# Orchestrator for the OpenShift platform test (CI runner or laptop; see README.md). Builds a code
# bundle, creates an in-VPC worker VM, streams code + secrets to it over IAP, runs run-on-vm.sh there,
# and deletes the VM. Invoked by `make run-test`.
set -uo pipefail

TESTDIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(git -C "${TESTDIR}" rev-parse --show-toplevel)"

TOOLBOX_DIR="${TOOLBOX_DIR:-}"
if [ -z "${TOOLBOX_DIR}" ]; then
  if command -v helm-test >/dev/null 2>&1; then
    TOOLBOX_DIR="$(cd "$(dirname "$(command -v helm-test)")/../.." && pwd)"
  else
    echo "FATAL: set TOOLBOX_DIR to the grafana/helm-chart-toolbox checkout" >&2; exit 1
  fi
fi

GCP_KEY_FILE="${GCP_KEY_FILE:-${GOOGLE_CLOUD_KEYFILE_JSON:-${GOOGLE_APPLICATION_CREDENTIALS:-}}}"
[ -s "${GCP_KEY_FILE:-}" ] || { echo "FATAL: no GCP key file (GCP_KEY_FILE / GOOGLE_CLOUD_KEYFILE_JSON / GOOGLE_APPLICATION_CREDENTIALS)" >&2; exit 1; }

PROJECT="${GCP_PROJECT:-grafana-k8s-monitoring}"
ZONE="${GCP_ZONE:-us-west1-b}"
VM="openshift-ci-${GITHUB_RUN_ID:-local}-${RANDOM}"
WORKTMP="$(mktemp -d)"
BUNDLE="${WORKTMP}/bundle.tgz"
WORKER="source/charts/k8s-monitoring/tests/platform/openshift/run-on-vm.sh"
# Keepalive so the IAP tunnel survives the long (~40 min) install/destroy.
SSH_FLAGS=(--tunnel-through-iap
  --ssh-flag=-oStrictHostKeyChecking=no --ssh-flag=-oUserKnownHostsFile=/dev/null
  --ssh-flag=-oServerAliveInterval=60 --ssh-flag=-oServerAliveCountMax=15)

log() { echo "[$(date +%H:%M:%S)] $*"; }

# shellcheck disable=SC2317,SC2329  # cleanup runs via 'trap cleanup EXIT'
cleanup() {
  log "Deleting worker VM ${VM}"
  gcloud compute instances delete "${VM}" --project="${PROJECT}" --zone="${ZONE}" --quiet >/dev/null 2>&1 || true
  rm -rf "${WORKTMP}" "${TESTDIR}/grafana-cloud-credentials.yaml"
}
trap cleanup EXIT

mkdir -p "${HOME}/.ssh"
[ -f "${HOME}/.ssh/google_compute_engine" ] || ssh-keygen -t rsa -f "${HOME}/.ssh/google_compute_engine" -N "" -q

log "Building code bundle"
mkdir -p "${WORKTMP}/staging/source" "${WORKTMP}/staging/helm-chart-toolbox"
rsync -a --exclude='.git' --exclude='.context' --exclude='*-installer-files' \
  --exclude='grafana-cloud-credentials.yaml' --exclude='gcp_service_account_key.json' \
  --exclude='kubeconfig.yaml' "${REPO_DIR}/" "${WORKTMP}/staging/source/" >/dev/null
rsync -a --exclude='.git' "${TOOLBOX_DIR}/" "${WORKTMP}/staging/helm-chart-toolbox/" >/dev/null
# COPYFILE_DISABLE=1 keeps macOS tar from adding AppleDouble "._*" files that break helm on Linux.
COPYFILE_DISABLE=1 tar -czf "${BUNDLE}" -C "${WORKTMP}/staging" source helm-chart-toolbox

log "Generating Grafana Cloud secret manifest"
make -C "${TESTDIR}" clean all >/dev/null
[ -s "${TESTDIR}/grafana-cloud-credentials.yaml" ] || { echo "FATAL: secret manifest missing" >&2; exit 1; }

log "Creating worker VM ${VM} in ${PROJECT}/${ZONE}"
# --max-run-duration=DELETE is a backstop: GCE auto-deletes the VM (and its tmpfs key) after 2h even
# if the orchestrator dies before cleanup runs.
gcloud compute instances create "${VM}" --project="${PROJECT}" --zone="${ZONE}" \
  --machine-type=e2-standard-4 --network=default --subnet=default --no-address \
  --no-service-account --no-scopes \
  --max-run-duration=7200s --instance-termination-action=DELETE \
  --image-family=ubuntu-2404-lts-amd64 --image-project=ubuntu-os-cloud \
  --labels=source=k8s-monitoring-helm-platform-test >/dev/null || { echo "FATAL: VM create failed" >&2; exit 1; }

log "Waiting for IAP SSH"
ok=false
for _ in $(seq 1 30); do
  if gcloud compute ssh "${VM}" --zone="${ZONE}" "${SSH_FLAGS[@]}" --command=true 2>/dev/null; then ok=true; break; fi
  sleep 10
done
[ "${ok}" = true ] || { echo "FATAL: IAP SSH never came up" >&2; exit 1; }

log "Transferring bundle"
gcloud compute ssh "${VM}" --zone="${ZONE}" "${SSH_FLAGS[@]}" --command="cat > ~/bundle.tgz" < "${BUNDLE}"

log "Streaming GCP key"
gcloud compute ssh "${VM}" --zone="${ZONE}" "${SSH_FLAGS[@]}" --command="umask 077; cat > /dev/shm/gcp-key.json" < "${GCP_KEY_FILE}"

log "Running worker on VM"
gcloud compute ssh "${VM}" --zone="${ZONE}" "${SSH_FLAGS[@]}" --command="
  set -euo pipefail
  rm -rf ~/work && mkdir -p ~/work
  tar -xzf ~/bundle.tgz -C ~/work
  find ~/work -name '._*' -delete
  cd ~/work
  bash ${WORKER}
" < "${TESTDIR}/grafana-cloud-credentials.yaml"
rc=$?
log "Test finished with exit code ${rc}"
exit "${rc}"
