---
description: Triage a GitHub issue — classify it, identify affected versions, and plan a fix
argument-hint: <github-issue-url>
allowed-tools: WebFetch, Read, Grep, Glob, Bash, Agent, EnterPlanMode
---

Triage the GitHub issue at $ARGUMENTS.

Follow these steps in order:

## Step 1: Fetch and understand the issue

Use WebFetch to read the GitHub issue page. Extract:
- The issue title and description
- Any error messages, logs, or stack traces
- The user's Helm chart version and configuration (if provided)
- Any reproduction steps

## Step 2: Classify the issue

Determine whether this is:
- **A legitimate bug** — something is broken in the chart code or templates
- **A documentation issue** — the chart works as designed but the docs are unclear, missing, or misleading
- **A configuration error** — the user misconfigured something and needs guidance
- **A feature request** — the user wants new functionality that doesn't exist yet
- **Not an issue** — the reported behavior is expected and correct

Explain your reasoning clearly.

## Step 3: Identify affected versions

Based on the issue details:
- Determine which chart version(s) are affected. Check `charts/k8s-monitoring/Chart.yaml` for the current version.
- If the issue mentions a specific version, note it.
- Check git history (`git log`) to see if the relevant code was recently changed, which helps identify when the issue was introduced.
- State whether the issue affects the latest version.

## Step 4: Plan the fix (if warranted)

If a code or documentation fix is warranted, enter plan mode and create a detailed plan:
- Identify the specific files that need to change
- Describe what changes are needed in each file
- Note any tests that should be added or updated
- Flag any risks or breaking changes the fix might introduce

If no fix is warranted (e.g., configuration error), instead draft a helpful response to the issue author explaining the resolution.

## Output format

Present your findings as a structured triage report with clear sections for each step above.
