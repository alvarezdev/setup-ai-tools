---
name: graphify
description: Use when exploring an unfamiliar codebase, tracing an implementation across files, or evaluating architecture before broad text search or edits.
---

# Graphify

Use the current project graph before a broad search. Query the relevant flow,
then open the cited source files and verify them; antes de modificar, confirma
la evidencia en los archivos reales.

```bash
graphify query "How does install.sh provision Claude and Codex?"
graphify path "install.sh script" "ensure_skill_link()"
graphify explain install.sh
```

If no current graph exists, say so and use `rg` plus direct source reading; do
not infer results. Build or refresh the graph deliberately with `graphify .`
or `graphify update .`, respecting `.graphifyignore`. Do not run Graphify's
platform installers: this repository publishes this wrapper as a managed
symlink for Claude and Codex.
