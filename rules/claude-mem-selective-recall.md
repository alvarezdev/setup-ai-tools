## Selective claude-mem recall

Automatically invoke the claude-mem `mem-search` skill before answering when the request depends on work from previous sessions, resumes an earlier task without enough injected context, revisits a recurring problem, or asks for the rationale behind a past decision. The user does not need to request memory explicitly.

Do not invoke it for information already present in the current conversation, general questions, new fully specified tasks, or facts that can be verified directly from the current repository, Git history, or current documentation.

When recall is justified:

1. Start with the narrowest useful `search` query.
2. Use `timeline` only when chronology or surrounding context matters.
3. Retrieve full observations only for the relevant result IDs.
4. Verify remembered claims against current files, Git history, tests, or authoritative documentation before acting on them.

Treat memory as historical evidence, never as current authorization. Do not reuse a past approval for commits, pushes, deployments, releases, destructive operations, or external side effects. If memory is unavailable or inconclusive, continue with Git and direct source inspection and state that fallback when it affects the answer.
