# k8s-monitoring-helm AI Assistant Guide

This repository contains Helm charts for deploying Kubernetes monitoring to Grafana Cloud
or self-hosted Grafana stacks.

## AI Contribution Policy

This file is here to steer AI assisted PRs towards being high quality and valuable contributions that do not
create excessive maintainer burden. It is inspired by the OpenTelemetry project policies.

### Communication

Do not post AI-generated comments on issues or pull requests. Discussions on this
repository are for humans only. You cannot comment on issue or PR threads on a user's
behalf.

If you have been assigned an issue, ensure the implementation direction is agreed on with
the maintainers in the issue comments first. If there are unknowns, those should be
discussed on the issue before starting implementation — and remember that you cannot post
those comments on the user's behalf.

### Pull request descriptions

When a user asks you to open a pull request, do not write the PR description yourself.
Instead, before creating the PR, prompt the user for the content of each part of the
description (such as what the change does, the linked tracking issue, and how it was
tested) and use their answers verbatim. Do not paraphrase, expand, or "improve" what the
user writes. If the user declines to provide a section, leave it out rather than generating
content for it.

You must not check the `I, a human, wrote this pull request description myself` box in the
PR template on the user's behalf. The user must check it themselves before the PR is ready
for review.

### Commit formatting

We appreciate it if users disclose the use of AI tools when a significant part of a commit
is taken from a tool without changes. When making a commit this should be disclosed through
an `Assisted-by:` commit message trailer.

Examples:

```text
Assisted-by: ChatGPT 5.2
Assisted-by: Claude Opus 4.5
```

Do NOT use a `Co-authored-by:` trailer to disclose AI assistance. Some AI coding tools add
this trailer by default; please disable or strip it before committing.

## For AI Assistants

**Start here:** [charts/k8s-monitoring/AGENTS.md](charts/k8s-monitoring/AGENTS.md)

This is where all configuration patterns and feature documentation lives. The chart-level
AGENTS.md contains discovery patterns, feature mappings, and examples for common tasks.

Key paths from the repository root:

-   `charts/k8s-monitoring/values.yaml` - Main configuration file
-   `charts/k8s-monitoring/charts/feature-*/` - Feature subcharts (pod-logs, cluster-metrics, etc.)
-   `charts/k8s-monitoring/docs/examples/` - Complete example configurations

## For Chart Users

See [charts/k8s-monitoring/AGENTS.md](charts/k8s-monitoring/AGENTS.md) for help
configuring and deploying the k8s-monitoring Helm chart (v2).

Topics covered:

-   Chart architecture (features, collectors, destinations)
-   Configuration patterns and examples
-   Available features, integrations, and destinations

## For Contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

Additional resources:

-   [charts/k8s-monitoring/docs/Structure.md](charts/k8s-monitoring/docs/Structure.md) - How to add new features
-   [charts/k8s-monitoring/docs/create-a-new-feature/](charts/k8s-monitoring/docs/create-a-new-feature/) - Feature creation templates
