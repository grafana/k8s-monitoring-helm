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
    ("addresses", []),
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


class Cleanup:
    def __init__(self) -> None:
        self.failures = 0

    def destroy_okd_clusters(self) -> None:
        log("== Phase 1: OpenShift (OKD) clusters ==")
        # OKD stamps every cluster resource with a kubernetes-io-cluster-<infraID> label; a
        # regional resource yields the destroy region directly, a zonal one via its zone prefix.
        newest: dict[str, int] = {}
        region: dict[str, str] = {}
        for kind in ("instances", "disks", "addresses", "images", "forwarding-rules"):
            for r in gcloud_json(["compute", kind, "list"]):
                created = epoch_of(r.get("creationTimestamp", ""))
                reg = region_of(r)
                for key in (r.get("labels") or {}):
                    if not key.startswith("kubernetes-io-cluster-"):
                        continue
                    infra = key[len("kubernetes-io-cluster-"):]
                    newest[infra] = max(newest.get(infra, 0), created)
                    if reg and not region.get(infra):
                        region[infra] = reg

        if not newest:
            log("No OKD clusters found.")
            return

        for infra, ts in newest.items():
            if not (0 < ts < CUTOFF_EPOCH):
                log(f"Keeping OKD cluster {infra} (newer than {MAX_AGE_HOURS}h or unknown age).")
                continue
            reg = region.get(infra) or OKD_REGION_DEFAULT
            log(f"Destroying OKD cluster {infra} in {reg}.")
            self._destroy_okd(infra, reg)

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

    def delete_gke_clusters(self) -> None:
        log("== Phase 2: GKE clusters ==")
        clusters = gcloud_json(["container", "clusters", "list"])
        if not clusters:
            log("No GKE clusters found.")
            return
        for c in clusters:
            name, location = c.get("name", ""), c.get("location", "")
            if not name:
                continue
            if not old_enough(c.get("createTime", "")):
                log(f"Keeping GKE cluster {name} (newer than {MAX_AGE_HOURS}h or unknown age).")
                continue
            log(f"Deleting GKE cluster {name} ({location}).")
            if not do_delete([
                "gcloud", "container", "clusters", "delete", name,
                f"--location={location}", f"--project={PROJECT}", "--quiet",
            ]):
                self.failures += 1

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
            # gcloud storage names the timestamp creation_time; timeCreated is the legacy fallback.
            created = b.get("creation_time") or b.get("timeCreated") or ""
            if not old_enough(created):
                log(f"Keeping bucket {name} (newer than {MAX_AGE_HOURS}h or unknown age).")
                continue
            log(f"Deleting bucket gs://{name}.")
            do_delete(["gcloud", "storage", "rm", "--recursive", f"gs://{name}"])

    def run(self) -> int:
        log("GCP test-resource cleanup")
        log(f"  project={PROJECT} max_age_hours={MAX_AGE_HOURS} dry_run={str(DRY_RUN).lower()}")
        log(f"  cutoff (UTC epoch)={CUTOFF_EPOCH}")
        self.destroy_okd_clusters()
        self.delete_gke_clusters()
        self.sweep_orphans()
        self.delete_buckets()
        if self.failures > 0:
            warn(f"cleanup finished with {self.failures} failure(s) in cluster teardown.")
            return 1
        log("Cleanup complete.")
        return 0


if __name__ == "__main__":
    sys.exit(Cleanup().run())
