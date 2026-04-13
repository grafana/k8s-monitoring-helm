---
description: Triage the N most recent GitHub issues — categorize each and write per-issue files
argument-hint: <number-of-issues>
allowed-tools: WebFetch, Read, Grep, Glob, Bash, Agent, Write, Edit
---

# Triage Bugs

Triage the most recent $ARGUMENTS open GitHub issues from the grafana/k8s-monitoring-helm repository.

If $ARGUMENTS is empty or not a number, default to 10.

## Step 1: Fetch the issues

Use Bash to list the most recent open issues:

```shell
gh issue list --repo grafana/k8s-monitoring-helm --limit <N> --state open --json number,title,url,labels,body

```

## Step 1.5: Check for existing triage reports

Check the `daily-triage/issues/` directory for existing files. If a file already exists for an issue (e.g. `daily-triage/issues/1234.md`), skip that issue entirely — do not re-triage it. Only process issues that do not already have a triage report.

## Step 2: For each issue, categorize and write a file

For each **new** issue (no existing triage report), perform the following:

### 2a: Understand the issue

Read the issue body (from the JSON above). If the body is truncated or you need more context (e.g. comments), use WebFetch to read the full issue page at its GitHub URL.

Extract:

-   The issue title and description
-   Any error messages, logs, or stack traces
-   The user's Helm chart version and configuration (if provided)
-   Any reproduction steps

### 2b: Classify the issue

Determine which **one** of these categories best fits:

| Category | Description |
|---|---|
| **Chart Bug** | A legitimate bug — something is broken in the chart code or templates |
| **Documentation Issue** | The chart works as designed but the docs are unclear, missing, or misleading and need to change |
| **User Docs Mismatch** | The user is not seeing or reading the right documentation for their version |
| **User Misunderstanding** | The user misconfigured something or misunderstands how the chart works |
| **Feature Request** | The user wants new functionality that doesn't exist yet |
| **Other** | Doesn't fit the above categories (e.g. meta issues, release tracking, questions) |

### 2c: Create an action plan

Based on the classification:

-   **Chart Bug**: Identify the specific files and code that need to change. Describe what the fix looks like, including any tests that should be added or updated.
-   **Documentation Issue**: Identify which doc files need to change and what should be added/clarified.
-   **User Docs Mismatch**: Draft a response pointing the user to the correct documentation for their version.
-   **User Misunderstanding**: Draft a helpful response explaining the correct configuration or behavior.
-   **Feature Request**: Outline what implementing the feature would require (files, scope, risks).
-   **Other**: Describe what action (if any) should be taken.

To build the action plan, use the codebase: search for relevant files, read templates, check values.yaml, etc. The plan should be specific enough that someone could start implementing from it.

### 2d: Write the issue file

Write a file to `daily-triage/issues/<number>.md` with this format:

```markdown
# <Issue Title>

-   **Issue:** <GitHub URL>
-   **Category:** <one of: Chart Bug, Documentation Issue, User Docs Mismatch, User Misunderstanding, Feature Request, Other>
-   **Triaged:** <current date, e.g. 2026-04-13>

## Description

<Brief summary of the issue in 2-3 sentences>

## Action Plan

<Specific steps to resolve, with file paths and code references where applicable>

```

## Step 3: Write a summary

After processing all issues, write a summary file to `daily-triage/summary.md` with a table listing all triaged issues:

```markdown
# Daily Triage Summary — <current date>

| Issue | Title | Category |
|---|---|---|
| [#1234](url) | Title | Category |

```

Note: Only include newly triaged issues in the summary table. Mention any skipped issues (already triaged) at the bottom.

Then output the summary to the user.
