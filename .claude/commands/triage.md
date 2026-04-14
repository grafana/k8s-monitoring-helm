---
description: Triage a GitHub issue — classify it, identify affected versions, and plan a fix
argument-hint: <github-issue-url> [--save]
allowed-tools: WebFetch, Read, Grep, Glob, Bash, Agent, Write, Edit, EnterPlanMode
---

# Triage

Triage the GitHub issue at $ARGUMENTS.

If `--save` is present in $ARGUMENTS, write the triage output to `daily-triage/issues/<number>.md` instead of presenting it in the conversation. Do not enter plan mode when `--save` is set.

Follow these steps in order:

## Step 1: Fetch and understand the issue

Use WebFetch to read the GitHub issue page. Extract:

-   The issue title and description
-   Any error messages, logs, or stack traces
-   The user's Helm chart version and configuration (if provided)
-   Any reproduction steps

## Step 2: Classify the issue

Determine which **one** of these categories best fits:

| Category | Description |
|---|---|
| **Chart Bug** | A legitimate bug — something is broken in the chart code or templates |
| **Documentation Issue** | The chart works as designed but the docs are unclear, missing, or misleading and need to change |
| **User Docs Mismatch** | The user is not seeing or reading the right documentation for their version |
| **User Misunderstanding** | The user misconfigured something or misunderstands how the chart works |
| **Feature Request** | The user wants new functionality that doesn't exist yet |
| **Other** | Doesn't fit the above categories (e.g. meta issues, release tracking, questions) |

Explain your reasoning.

## Step 3: Identify affected versions

Based on the issue details:

-   Determine which chart version(s) are affected. Check `charts/k8s-monitoring/Chart.yaml` for the current version.
-   If the issue mentions a specific version, note it.
-   Check git history (`git log`) to see if the relevant code was recently changed, which helps identify when the issue was introduced.
-   State whether the issue affects the latest version.

## Step 4: Create an action plan

Based on the classification:

-   **Chart Bug**: Identify the specific files and code that need to change. Describe what the fix looks like, including any tests that should be added or updated.
-   **Documentation Issue**: Identify which doc files need to change and what should be added/clarified.
-   **User Docs Mismatch**: Draft a response pointing the user to the correct documentation for their version.
-   **User Misunderstanding**: Draft a helpful response explaining the correct configuration or behavior.
-   **Feature Request**: Outline what implementing the feature would require (files, scope, risks).
-   **Other**: Describe what action (if any) should be taken.

To build the action plan, search for relevant files, read templates, check values.yaml, etc. The plan should be specific enough that someone could start implementing from it.

## Step 5: Output

**If `--save` was specified**, write a file to `daily-triage/issues/<number>.md`:

```markdown
# <Issue Title>

-   **Issue:** <GitHub URL>
-   **Category:** <one of the categories above>
-   **Triaged:** <current date, e.g. 2026-04-13>

## Description

<Brief summary of the issue in 2-3 sentences>

## Action Plan

<Specific steps to resolve, with file paths and code references where applicable>
```

**If `--save` was not specified**, present findings as a structured triage report in the conversation with clear sections for each step above. Then, if the issue is a **Chart Bug**, enter plan mode and create a detailed implementation plan.
