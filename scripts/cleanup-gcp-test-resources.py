#!/usr/bin/env python3
from __future__ import annotations

import datetime as dt
import json
import os
import subprocess
import sys
import tempfile

# hard-coded, not env-overridable: this destructive tool must only ever target the test project
PROJECT = "grafana-helm-chart-tests"
OKD_REGION_DEFAULT = os.environ.get("OKD_REGION", "us-central1")
MAX_AGE_HOURS = int(os.environ.get("MAX_AGE_HOURS", "6"))
# fail safe: only an explicit "false" disables dry-run, so a typo can't trigger real deletes
DRY_RUN = os.environ.get("DRY_RUN", "true").strip().lower() != "false"

CUTOFF_EPOCH = int((dt.datetime.now(dt.timezone.utc) - dt.timedelta(hours=MAX_AGE_HOURS)).timestamp())

# Global types whose `delete` subcommand defaults to global scope and rejects --global.
GLOBAL_NO_FLAG = {"images", "firewall-rules", "networks", "http-health-checks", "https-health-checks"}

# Phase 3 sweep, in reverse-dependency order, with any extra list args.
SWEEP_TYPES: list[tuple[str, list[str]]] = [
    # GKE nodes are managed by their cluster (Phase 2); never delete them directly here.
    ("instances", ["--filter=NOT labels.goog-k8s-cluster-name:*"]),
    ("target-pools", []),
    ("forwarding-rules", []),
    ("backend-services", []),
    ("url-maps", []),
    ("target-http-proxies", []),
    ("target-https-proxies", []),
    ("health-checks", []),
    ("http-health-checks", []),
    ("https-health-checks", []),
    # NAT_AUTO addresses are managed by their Cloud NAT router (standing infra); never sweep them.
    ("addresses", ["--filter=purpose!=NAT_AUTO"]),
    ("disks", []),
    ("images", ["--no-standard-images"]),
    ("firewall-rules", ["--filter=network!~/networks/default$"]),
    ("routers", ["--filter=network!~/networks/default$"]),
    ("subnetworks", ["--filter=name!=default"]),
    ("networks", ["--filter=name!=default"]),
]


def log(msg: str) -> None:
    print(msg, flush=True)


def warn(msg: str) -> None:
    print(f"WARN: {msg}", file=sys.stderr, flush=True)


def epoch_of(ts: str) -> int:
    if not ts:
        return 0
    try:
        return int(dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp())
    except ValueError:
        return 0


# unknown age -> keep
def old_enough(ts: str) -> bool:
    ep = epoch_of(ts)
    return 0 < ep < CUTOFF_EPOCH


def basename(url: str) -> str:
    return url.rsplit("/", 1)[-1] if url else ""


def gcloud_json(args: list[str]) -> list[dict]:
    try:
        out = subprocess.run(
            ["gcloud", *args, f"--project={PROJECT}", "--format=json"],
            capture_output=True, text=True, check=True,
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    try:
        return json.loads(out) if out.strip() else []
    except json.JSONDecodeError:
        return []


def do_delete(args: list[str]) -> bool:
    if DRY_RUN:
        log("DRY-RUN would run: " + " ".join(args))
        return True
    if subprocess.run(args).returncode == 0:
        return True
    warn("command failed: " + " ".join(args))
    return False


def region_of(r: dict) -> str:
    if r.get("region"):
        return basename(r["region"])
    if r.get("zone"):
        return "-".join(basename(r["zone"]).split("-")[:-1])
    return ""


# keep wins over age: compute uses .labels, GKE uses .resourceLabels; any non-"false" value protects.
def wants_keep(r: dict) -> bool:
    labels = {**(r.get("labels") or {}), **(r.get("resourceLabels") or {})}
    v = labels.get("keep")
    return v is not None and v.strip().lower() != "false"


# A kept cluster's dependents often can't be keep-labeled (OKD's router/firewall/LB, or any
# unlabeled resource), so match them by ownership: OKD names everything <infraID>-* and labels
# kubernetes-io-cluster-<infraID>; GKE stamps goog-k8s-cluster-name. Returns the owner id or "".
def kept_cluster_of(r: dict, name: str, kept_okd: set[str], kept_gke: set[str]) -> str:
    labels = {**(r.get("labels") or {}), **(r.get("resourceLabels") or {})}
    gke = labels.get("goog-k8s-cluster-name", "")
    if gke and gke in kept_gke:
        return gke
    for infra in kept_okd:
        if name.startswith(f"{infra}-") or f"kubernetes-io-cluster-{infra}" in labels:
            return infra
    return ""


class Cleanup:
    def __init__(self) -> None:
        self.failures = 0
        self.kept_okd: set[str] = set()
        self.kept_gke: set[str] = set()

    def destroy_okd_clusters(self) -> set[str]:
        log("== Phase 1: OpenShift (OKD) clusters ==")
        # OKD stamps every cluster resource with a kubernetes-io-cluster-<infraID> label; a
        # regional resource yields the destroy region directly, a zonal one via its zone prefix.
        newest: dict[str, int] = {}
        region: dict[str, str] = {}
        keep: dict[str, bool] = {}
        for kind in ("instances", "disks", "addresses", "images", "forwarding-rules"):
            for r in gcloud_json(["compute", kind, "list"]):
                created = epoch_of(r.get("creationTimestamp", ""))
                reg = region_of(r)
                kept = wants_keep(r)
                for key in (r.get("labels") or {}):
                    if not key.startswith("kubernetes-io-cluster-"):
                        continue
                    infra = key[len("kubernetes-io-cluster-"):]
                    newest[infra] = max(newest.get(infra, 0), created)
                    if reg and not region.get(infra):
                        region[infra] = reg
                    if kept:
                        keep[infra] = True

        if not newest:
            log("No OKD clusters found.")
            return set()

        kept_ids: set[str] = set()
        for infra, ts in newest.items():
            if keep.get(infra):
                log(f"Keeping OKD cluster {infra} (keep label).")
                kept_ids.add(infra)
                continue
            if not (0 < ts < CUTOFF_EPOCH):
                log(f"Keeping OKD cluster {infra} (newer than {MAX_AGE_HOURS}h or unknown age).")
                kept_ids.add(infra)
                continue
            reg = region.get(infra) or OKD_REGION_DEFAULT
            log(f"Destroying OKD cluster {infra} in {reg}.")
            self._destroy_okd(infra, reg)
        return kept_ids

    def _destroy_okd(self, infra: str, region: str) -> None:
        with tempfile.TemporaryDirectory() as d:
            metadata = {
                "clusterName": infra, "clusterID": "", "infraID": infra,
                "gcp": {"projectID": PROJECT, "region": region},
            }
            with open(os.path.join(d, "metadata.json"), "w") as f:
                json.dump(metadata, f)
            if DRY_RUN:
                log(f"DRY-RUN would run: openshift-install destroy cluster --dir {d} (infraID={infra})")
                return
            rc = subprocess.run(
                ["openshift-install", "destroy", "cluster", "--dir", d, "--log-level=info"]
            ).returncode
            if rc != 0:
                warn(f"openshift-install destroy failed for {infra}")
                self.failures += 1

    def delete_gke_clusters(self) -> set[str]:
        log("== Phase 2: GKE clusters ==")
        clusters = gcloud_json(["container", "clusters", "list"])
        if not clusters:
            log("No GKE clusters found.")
            return set()
        kept: set[str] = set()
        for c in clusters:
            name, location = c.get("name", ""), c.get("location", "")
            if not name:
                continue
            if wants_keep(c):
                log(f"Keeping GKE cluster {name} (keep label).")
                kept.add(name)
                continue
            if not old_enough(c.get("createTime", "")):
                log(f"Keeping GKE cluster {name} (newer than {MAX_AGE_HOURS}h or unknown age).")
                kept.add(name)
                continue
            # --async: fire-and-forget. The call still fails loudly on auth/permission/not-found,
            # but we don't wait on the server-side delete; a stuck cluster is re-issued next run.
            log(f"Deleting GKE cluster {name} ({location}) (async).")
            if not do_delete([
                "gcloud", "container", "clusters", "delete", name,
                f"--location={location}", f"--project={PROJECT}", "--async", "--quiet",
            ]):
                self.failures += 1
        return kept

    def sweep_orphans(self) -> None:
        log("== Phase 3: orphaned compute resources ==")
        # Two passes: LB/instance teardown frees the networks/subnets deleted at the end.
        for pass_num in (1, 2):
            log(f"-- sweep pass {pass_num} --")
            for rtype, extra in SWEEP_TYPES:
                self._sweep_compute(rtype, extra)

    def _sweep_compute(self, rtype: str, extra: list[str]) -> None:
        for r in gcloud_json(["compute", rtype, "list", *extra]):
            name = r.get("name", "")
            if not name:
                continue
            if wants_keep(r):
                log(f"Keeping {rtype}/{name} (keep label).")
                continue
            owner = kept_cluster_of(r, name, self.kept_okd, self.kept_gke)
            if owner:
                log(f"Keeping {rtype}/{name} (belongs to kept cluster {owner}).")
                continue
            # in-use resources can't be deleted anyway; a managed disk goes with its cluster (Phase 2).
            if r.get("users"):
                log(f"Keeping {rtype}/{name} (in use).")
                continue
            if not old_enough(r.get("creationTimestamp", "")):
                log(f"Keeping {rtype}/{name} (newer than {MAX_AGE_HOURS}h or unknown age).")
                continue
            log(f"Deleting {rtype}/{name}.")
            base = ["gcloud", "compute", rtype, "delete", name]
            tail = [f"--project={PROJECT}", "--quiet"]
            if r.get("zone"):
                do_delete(base + ["--zone", basename(r["zone"])] + tail)
            elif r.get("region"):
                do_delete(base + ["--region", basename(r["region"])] + tail)
            elif rtype in GLOBAL_NO_FLAG:
                do_delete(base + tail)
            else:
                do_delete(base + ["--global"] + tail)

    def delete_buckets(self) -> None:
        log("== Phase 4: storage buckets ==")
        buckets = gcloud_json(["storage", "buckets", "list"])
        if not buckets:
            log("No buckets found.")
            return
        for b in buckets:
            name = b.get("name", "")
            if not name:
                continue
            if wants_keep(b):
                log(f"Keeping bucket {name} (keep label).")
                continue
            owner = kept_cluster_of(b, name, self.kept_okd, self.kept_gke)
            if owner:
                log(f"Keeping bucket {name} (belongs to kept cluster {owner}).")
                continue
            # gcloud storage names the timestamp creation_time; timeCreated is the legacy fallback.
            created = b.get("creation_time") or b.get("timeCreated") or ""
            if not old_enough(created):
                log(f"Keeping bucket {name} (newer than {MAX_AGE_HOURS}h or unknown age).")
                continue
            log(f"Deleting bucket gs://{name}.")
            do_delete(["gcloud", "storage", "rm", "--recursive", f"gs://{name}"])

    # Since GKE deletes are async (unwatched), this is the only visibility into what is left:
    # just-issued clusters show STOPPING, kept ones RUNNING, a stuck one would persist here.
    def summarize(self) -> None:
        log("== Remaining GKE clusters ==")
        clusters = gcloud_json(["container", "clusters", "list"])
        if not clusters:
            log("  (none)")
            return
        for c in sorted(clusters, key=lambda c: c.get("name", "")):
            log(f"  {c.get('name', '')} ({c.get('location', '')}, {c.get('status', '')})")

    def run(self) -> int:
        log("GCP test-resource cleanup")
        log(f"  project={PROJECT} max_age_hours={MAX_AGE_HOURS} dry_run={str(DRY_RUN).lower()}")
        log(f"  cutoff (UTC epoch)={CUTOFF_EPOCH}")
        self.kept_okd = self.destroy_okd_clusters()
        self.kept_gke = self.delete_gke_clusters()
        self.sweep_orphans()
        self.delete_buckets()
        self.summarize()
        if self.failures > 0:
            warn(f"cleanup finished with {self.failures} failure(s) in cluster teardown.")
            return 1
        log("Cleanup complete.")
        return 0


if __name__ == "__main__":
    sys.exit(Cleanup().run())
