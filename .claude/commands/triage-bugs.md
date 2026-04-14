---
description: Triage the N most recent GitHub issues — categorize each and write per-issue files
argument-hint: <number-of-issues|all>
allowed-tools: WebFetch, Read, Grep, Glob, Bash, Agent, Write, Edit
---

# Triage Bugs

Triage open GitHub issues from the grafana/k8s-monitoring-helm repository.

- If $ARGUMENTS is `all`, fetch every open issue.
- If $ARGUMENTS is a number, fetch that many most recent open issues.
- If $ARGUMENTS is empty or not a number or `all`, default to 10.

## Step 1: Fetch the issues

Use Bash to list the open issues. If fetching all, omit `--limit` (or use a large value like `--limit 1000`):

```shell
# For a specific count:
gh issue list --repo grafana/k8s-monitoring-helm --limit <N> --state open --json number,title,url,labels,body

# For all issues:
gh issue list --repo grafana/k8s-monitoring-helm --limit 1000 --state open --json number,title,url,labels,body
```

## Step 2: Check for existing triage reports

Check the `daily-triage/issues/` directory for existing files. If a file already exists for an issue (e.g. `daily-triage/issues/1234.md`), skip that issue entirely — do not re-triage it. Only process issues that do not already have a triage report.

## Step 3: Triage each new issue

For each **new** issue (no existing triage report), follow all steps in `.claude/commands/triage.md` using the issue URL and the `--save` flag. This will write the triage output to `daily-triage/issues/<number>.md`.

Process issues in parallel where possible.

## Step 4: Write a summary

After processing all issues, write a summary file to `daily-triage/summary.md`:

```markdown
# Daily Triage Summary — <current date>

| Issue | Title | Category |
|---|---|---|
| [#1234](url) | Title | Category |
```

Only include newly triaged issues in the summary table. Mention any skipped issues (already triaged) at the bottom.

Then output the summary to the user.
