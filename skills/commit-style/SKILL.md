---
name: commit-style
description: >-
  Generate Conventional Commits proposals from the actual repository diff, with
  short imperative English titles and concrete bullet bodies. Use when
  summarizing completed changes, proposing a commit title and description, or
  deciding whether a change set should be committed together. Applies to any
  project type: mobile, frontend, backend, scripts, CI, docs, infrastructure,
  APIs, tooling, or libraries. Does not run git push, deploys, releases, or
  remote actions, and runs local git commit only when the project Git policy or
  the user explicitly authorizes it.
---

# Commit Style Skill

## Purpose

Generate precise, consistent, and traceable commit message proposals from the
actual repository state.

The style favors:

- Conventional Commit prefix.
- Short English title with an imperative verb.
- Clear technical scope.
- Body with concrete bullet points.
- Explicit validation only when there is evidence it ran.
- Documentation, security, and compatibility notes when they apply.

It is not coupled to any specific project, framework, language, platform,
author, or source example.

---

## Non-negotiable rules

1. Do not invent changes. Inspect the actual repository state before proposing a
   commit (see "Inspect the repository state").

2. Do not run repository-changing Git actions by default.
   - No `git push`.
   - No branches, tags, releases, or pull requests.
   - No deploy or publish.
   - Run local `git commit` only when the project Git policy explicitly requires
     a checkpoint after a completed and validated step, or when the user
     explicitly authorizes it. If no policy authorizes it, only propose the
     message.

3. Keep all work local unless the user explicitly authorizes remote actions.

4. Write commit titles and bodies in English, unless the user explicitly asks
   for another language. Responses to the user follow the user's language (see
   "Language").

5. Prefer precision over generic wording.
   - Good: `feat: Implement child profile selector`
   - Good: `refactor: Move payment validation into service`
   - Good: `fix: Harden image upload validation`
   - Avoid: `feat: Improve app`
   - Avoid: `fix: Update things`

6. One commit represents one coherent change set. Do not mix unrelated features,
   refactors, tests, docs, and operational changes unless they directly support
   the same change.

7. Do not claim validation happened unless there is evidence. Only mention
   tests, build, lint, typecheck, emulator, simulator, browser, or manual
   validation when it was actually run or clearly shown in context.

---

## Inspect the repository state

Always run this before proposing or creating a commit. Referenced from every
mode below:

```bash
git status --short
git diff --stat
git diff --name-only
git diff
```

Then read relevant files when the diff alone is not enough to describe intent.

---

## Default commit title style

### Format

```text
<type>: <Imperative verb> <technical scope> <result or intent>
```

Examples:

```text
feat: Implement user onboarding flow
feat: Add child profile selector
fix: Harden image upload validation
fix: Prevent duplicate form submissions
refactor: Split authentication module by responsibility
chore: Configure environment variables for local development
test: Add integration tests for login flow
ci: Add pull request validation workflow
docs: Update setup guide with local development steps
```

### Allowed commit types

- `feat`: new functional behavior or capability.
- `fix`: bug fix, security hardening, unsafe or incorrect behavior correction.
- `refactor`: internal structure change without changing external behavior.
- `chore`: configuration, runtime, tooling, dependency management, local setup,
  maintenance, or operational setup.
- `test`: test coverage (unit, widget, integration, rules, e2e).
- `ci`: validation workflow, build automation, pipeline changes.
- `docs`: documentation-only changes.

Special case, only for the first commit of a new repository:

```text
Initial commit: <short baseline description>
```

---

## Title wording rules

### Use imperative verbs

```text
Add        Apply      Configure  Create     Enforce
Extract    Harden     Implement  Introduce  Move
Prepare    Prevent    Protect    Remove     Restructure
Set up     Split      Update     Upgrade    Use        Validate
```

### Keep titles specific

Name the domain, feature, layer, module, or technical surface: Authentication,
Dashboard, Navigation, Design system, API client, Data layer, Repository, State
management, Form validation, Image upload, Error handling, Environment config,
CI workflow, README.

### Avoid vague titles

Do not use: `update stuff`, `changes`, `fix bugs`, `improve project`,
`frontend changes`, `final changes`, `misc`, `wip`.

### No trailing period

- Good: `refactor: Move auth logic into module`
- Avoid: `refactor: Move auth logic into module.`

---

## Commit body style

### Default body format

Bullet points starting with `- `. Each bullet starts with an imperative verb and
describes one concrete change.

```text
<type>: <Imperative title>

- Add ...
- Move ...
- Protect ...
- Validate ...
- Document ...
```

### Body length

- 4 to 9 bullets for normal commits.
- 2 to 4 bullets for very small commits.
- 8 to 10 bullets for large but coherent commits.

### Body content order

1. Main implementation change.
2. Supporting structural changes.
3. Security, validation, or error handling behavior.
4. Compatibility or preserved behavior.
5. Tests, build, lint, or manual validation if actually performed.
6. Documentation updates.

### Common body patterns

Use only when they match the actual diff:

```text
- Add <module/service/repository/helper> for <purpose>
- Implement <flow/screen/endpoint/operation> with <technology>
- Move <logic> into <module/layer>
- Extract <concern> into <helper/service/repository>
- Protect <resource/route/endpoint/screen> with <auth/rules/role>
- Harden <validation/upload/path/auth/form> behavior
- Prevent <bug/duplicate action/invalid state>
- Keep <existing behavior/export/endpoint/screen> unchanged
- Add <test type> coverage for <scenario>
- Validate <lint/build/tests/integration/manual flow>
- Document <flow/setup/checklist> in the README
```

Full worked examples per project type live in `references/examples.md`. Load
that file when you need a concrete template to adapt.

---

## Operating modes

### Proposal mode (default)

Use when no project Git policy authorizes commits. Inspect the diff and propose a
message without staging or committing.

### Local checkpoint commit mode

Use only when the project Git policy explicitly allows local commits. Before
committing, the work must be complete, validated, coherent, free of secrets, and
limited to one logical change set. Never push after committing unless the user
explicitly asks.

---

## How to propose a commit after work is done

1. Run the inspection block ("Inspect the repository state") and read relevant
   files when needed.
2. Provide:

````markdown
## Suggested commit

```text
<type>: <title>

- <actual change>
- <actual change>
- <test/docs/validation if present>
```

## Why this type

<short explanation>

## Files considered

- <file 1>
- <file 2>
````

If tests were not run, say it clearly and do not claim validation happened:

```text
No puedo confirmar tests ejecutados porque no hay evidencia en la terminal ni en el diff.
```

---

## How to create a local checkpoint commit when authorized

Only when the project Git policy or the user explicitly authorizes local commits.

1. Run the inspection block ("Inspect the repository state").
2. Confirm the change set is coherent and free of secrets and unrelated files.
3. Confirm relevant validation ran, or clearly state what could not be validated.
4. Stage only the files that belong to the completed step:

```bash
git add <relevant-files>
```

5. Create the local commit:

```bash
git commit -m "<type>: <imperative technical title>" -m "- <actual change>" -m "- <actual change>"
```

6. Report the commit title and validation result.
7. Do not run `git push`.

---

## Commit type decision guide

- `feat`: a new screen, endpoint, flow, module capability, CLI command, or
  user-visible behavior is added.
- `fix`: a bug, security hole, invalid state, unsafe path, exposed data, broken
  UI, failed validation, or incorrect behavior is corrected.
- `refactor`: behavior is preserved but structure changes (logic moved into
  modules, services, hooks, controllers, providers, widgets, helpers; DI or
  explicit types introduced without new external behavior).
- `chore`: runtime, scripts, secrets handling, package updates, local setup,
  tooling, environment config, logs, guards, or operational configuration.
- `test`: the main change is test coverage.
- `ci`: the main change is a workflow or pipeline.
- `docs`: the main change is documentation only.

---

## Description checklist

Before finalizing the body, verify each bullet answers at least one of: what was
added, moved, extracted, protected, enforced, preserved, validated, or
documented. Remove any bullet not backed by the actual diff.

---

## Commit grouping checklist

Before proposing one commit, verify the change set is coherent:

- The files changed support the same goal.
- The title accurately covers the whole diff.
- The body does not hide unrelated changes.
- Tests or docs are included only when they directly support the same change.
- If unrelated changes exist, suggest splitting them into separate proposals.

---

## Language

- Commit titles and bodies: English by default, unless the user asks otherwise.
- Responses to the user: follow the user's language (default Spanish for this
  user). The templates below are in Spanish for that reason.

---

## Final response style for the agent

Be brief and useful:

````markdown
Listo. Con base en el diff actual, este seria el commit:

```text
<commit title>

- <bullet>
- <bullet>
```

No ejecute `git push` ni deploy.
````

If the diff contains unrelated changes:

```markdown
Veo cambios que seria mejor separar en mas de un commit:

1. `<type>: <title>` — <scope>
2. `<type>: <title>` — <scope>

No ejecute `git push` ni deploy.
```

---

## Style summary

A project-agnostic commit message style favoring technical clarity, coherent
change grouping, explicit validation only when available, security hardening
when relevant, and documentation updates when behavior, setup, architecture, or
operational workflows change.
