#!/usr/bin/env bash
# Worker for the OpenShift platform test — runs on the in-VPC VM, launched by run-test.sh (see
# README.md). CWD is the bundle root; the Grafana Cloud secret arrives on stdin, and the Google Cloud
# service-account key (a JSON credentials file, used to authenticate to Google Cloud) at
# /dev/shm/gcp-key.json.
set -euo pipefail

BIN=/usr/local/bin
TEST_DIRECTORY="source/charts/k8s-monitoring/tests/platform/openshift"
CREDS_TMPFS="/dev/shm/grafana-cloud-credentials.yaml"
CREDS_LINK="${TEST_DIRECTORY}/grafana-cloud-credentials.yaml"
GCP_KEY_TMPFS="/dev/shm/gcp-key.json"

umask 077
cat > "${CREDS_TMPFS}"
ln -sf "${CREDS_TMPFS}" "${CREDS_LINK}"

# Destroy the cluster and remove secrets on exit; retry destroy (idempotent) so a hiccup can't leak it.
# shellcheck disable=SC2317,SC2329  # cleanup runs via 'trap cleanup EXIT'
cleanup() {
  set +e
  rm -f "${CREDS_TMPFS}" "${CREDS_LINK}"
  for d in "${TEST_DIRECTORY}"/*-installer-files; do
    [ -d "${d}" ] || continue
    echo "Destroying cluster in ${d}"
    for attempt in 1 2 3 4 5 6; do
      openshift-install destroy cluster --dir "${d}" && break
      echo "destroy attempt ${attempt} failed; retrying in 30s"; sleep 30
    done
  done
  rm -f "${GCP_KEY_TMPFS}"
}
trap cleanup EXIT

# Tooling: pinned versions verified against hardcoded SHA-256 (bump version and hash together).
KUBECTL_VERSION=v1.36.2
KUBECTL_SHA256=1e9045ec32bea85da43de85f0065358529ea7c7a152eca78154fba5b58c27d82
HELM_VERSION=v4.1.4  # 4.2.x changes template output (helm/helm#32132)
HELM_SHA256=70b2c30a19da4db264dfd68c8a3664e05093a361cefd89572ffb36f8abfa3d09
YQ_VERSION=v4.53.3
YQ_SHA256=fa52a4e758c63d38299163fbdd1edfb4c4963247918bf9c1c5d31d84789eded4
FLUX_VERSION=v2.9.1
FLUX_SHA256=6e984c92aa02250ea3f907367dc7829411e31d667b100ce2005cb87d5509e5b3
KUSTOMIZE_VERSION=v5.8.1
KUSTOMIZE_SHA256=029a7f0f4e1932c52a0476cf02a0fd855c0bb85694b82c338fc648dcb53a819d
OKD_VERSION=4.22.0-okd-scos.6  # openshift-install
OKD_SHA256=f7631ca03503e4612efa572e4c7a9fd58e2da17c55fc027893a7a8817e505d9f

verify() { echo "$2  $1" | sha256sum -c - >/dev/null || { echo "FATAL: checksum mismatch for $1" >&2; exit 1; }; }

sudo apt-get update -y
sudo apt-get install -y curl tar jq git gettext-base

curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
verify /tmp/kubectl "${KUBECTL_SHA256}"
sudo install -m0755 /tmp/kubectl "${BIN}/kubectl"

curl -fsSLo /tmp/helm.tgz "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
verify /tmp/helm.tgz "${HELM_SHA256}"
sudo tar -xzf /tmp/helm.tgz -C /tmp linux-amd64/helm
sudo install -m0755 /tmp/linux-amd64/helm "${BIN}/helm"

curl -fsSLo /tmp/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
verify /tmp/yq "${YQ_SHA256}"
sudo install -m0755 /tmp/yq "${BIN}/yq"

curl -fsSLo /tmp/flux.tgz "https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/flux_${FLUX_VERSION#v}_linux_amd64.tar.gz"
verify /tmp/flux.tgz "${FLUX_SHA256}"
sudo tar -xzf /tmp/flux.tgz -C /tmp flux
sudo install -m0755 /tmp/flux "${BIN}/flux"

curl -fsSLo /tmp/kustomize.tgz "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
verify /tmp/kustomize.tgz "${KUSTOMIZE_SHA256}"
sudo tar -xzf /tmp/kustomize.tgz -C /tmp kustomize
sudo install -m0755 /tmp/kustomize "${BIN}/kustomize"

curl -fsSLo /tmp/oi.tgz "https://github.com/okd-project/okd/releases/download/${OKD_VERSION}/openshift-install-linux-${OKD_VERSION}.tar.gz"
verify /tmp/oi.tgz "${OKD_SHA256}"
sudo tar -xzf /tmp/oi.tgz -C "${BIN}" openshift-install

# openshift-install needs a key file; with only the VM's metadata/ADC it demands credentialsMode: Manual.
[ -f "${GCP_KEY_TMPFS}" ] || { echo "FATAL: GCP key not found at ${GCP_KEY_TMPFS}" >&2; exit 1; }
export GOOGLE_CLOUD_KEYFILE_JSON="${GCP_KEY_TMPFS}"
export KUBECONFIG="${PWD}/${TEST_DIRECTORY}/kubeconfig.yaml"
export TEST_DIRECTORY
export DELETE_CLUSTER=false

./helm-chart-toolbox/tools/helm-test/helm-test "${TEST_DIRECTORY}"
