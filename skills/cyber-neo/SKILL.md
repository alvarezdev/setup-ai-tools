---
name: cyber-neo
description: Use when the user requests a read-only security audit, vulnerability scan, or `/cyber-neo` for a local project in Claude Code.
---

# Cyber Neo

Run the preserved Cyber Neo upstream workflow for the target project. Never modify, delete, or create files in the target project. Do not run the target project or install, update, or remove its dependencies.

## Load the preserved upstream

Before reconnaissance, resolve the source repository and read its complete
runbook. The clone is managed by `setup-ai-tools`; do not edit it.

```bash
REPO_ROOT="$(cd "$(realpath "$CLAUDE_SKILL_DIR")/../.." && pwd)"
UPSTREAM_SKILL_DIR="$REPO_ROOT/cyber-neo/skills/cyber-neo"
test -f "$UPSTREAM_SKILL_DIR/SKILL.md"
```

Read `$UPSTREAM_SKILL_DIR/SKILL.md` and follow its reconnaissance, five
parallel analysis phases, severity rules, secret redaction, and report
structure. Resolve every upstream script and reference from
`$UPSTREAM_SKILL_DIR`, not from this wrapper. Preserve its read-only rules for
the project being audited and do not install optional tools automatically.

## Report destination override

The upstream runbook names the Desktop as its report destination. Replace only
that instruction with the following destination. Do not create this directory
at skill load or during reconnaissance; create it immediately before saving the
completed report in phase 7.

```bash
REPORT_DIR="$HOME/Documents/reports-cyber-neo"
mkdir -p "$REPORT_DIR"
REPORT_PATH="$REPORT_DIR/cyber-neo-report-{project-name}-{YYYY-MM-DD}.md"
```

Write exactly one report to `REPORT_PATH`, then tell the user its path and a
short, prioritized summary. The directory and report are the only permitted
writes outside the target project.
