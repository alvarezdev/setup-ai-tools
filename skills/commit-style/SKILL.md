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

Turn a finished change into a precise, traceable commit message in Conventional
Commits style: a short imperative English title and a body of concrete bullets,
grounded entirely in the real diff. Works in any repository (mobile, frontend,
backend, scripts, CI, docs, infra, tooling, libraries).

## Principles

The rules below all follow from a few ideas. Understanding the why makes the
judgment calls easier than memorizing commands.

**Ground every claim in the real diff.** A commit message is read far more often
than it is written: in `git blame`, in `git bisect`, in review months later. A
message that describes something the diff does not contain is worse than none,
because it sends the next person down the wrong path. So inspect the actual diff
first and describe only what it shows. Never describe intended or remembered
work.

**Default to the safe, reversible action.** Proposing a message costs nothing
and is easy to discard; running `git commit`, and especially `git push`, is not.
Whether and when to commit belongs to the project's Git policy or to the user,
not to this skill. So by default, only propose the message. Commit locally only
when a project policy (for example a documented checkpoint rule) or the user
explicitly authorizes it, and never push, deploy, tag, or open PRs unless asked
explicitly.

**Never claim validation that did not happen.** "Tests pass" or "build succeeds"
in a body is a factual claim others rely on to merge or deploy. If it was not
actually run, it is a lie that compounds downstream. Mention tests, build, lint,
typecheck, emulator, or manual checks only with real evidence they ran;
otherwise say plainly you could not verify them.

**One commit is one coherent change.** A commit is the unit of review and of
revert. When unrelated work rides together, a reviewer cannot approve one part
without the other, and reverting a bug fix also reverts a feature. Keep a single
commit to one coherent change set; if the diff mixes unrelated work, say so and
propose splitting it.

**Be specific, not generic.** The title is what people scan in a long log.
`fix: Update things` tells them nothing and forces them to open the diff. Name
the concrete surface that changed.

## Workflow

### 1. Inspect the real repository state

Always run this before proposing or creating a commit:

```bash
git status --short
git diff --stat
git diff --name-only
git diff
```

Read the relevant changed files when the diff alone does not make the intent
clear.

### 2. Decide the type

Pick the one type that captures the main point of the change:

- `feat`: adds new behavior or capability (screen, endpoint, flow, CLI command,
  user-visible behavior).
- `fix`: corrects a bug, security hole, invalid state, unsafe path, exposed
  data, broken UI, or failed validation.
- `refactor`: changes internal structure while preserving external behavior
  (moving logic into modules, services, hooks, providers, widgets, helpers;
  introducing DI or explicit types without new behavior).
- `chore`: configuration, tooling, dependencies, local setup, scripts, secrets
  handling, environment config, or operational maintenance.
- `test`: the main change is test coverage (unit, widget, integration, e2e).
- `ci`: the main change is a workflow or pipeline.
- `docs`: the main change is documentation only.

Special case, only for the very first commit of a new repository:
`Initial commit: <short baseline description>`.

### 3. Write the title

Format:

```text
<type>: <Imperative verb> <technical scope> <result or intent>
```

- Start the description with an imperative verb: Add, Apply, Configure, Create,
  Enforce, Extract, Harden, Implement, Introduce, Move, Prevent, Protect,
  Remove, Restructure, Set up, Split, Update, Upgrade, Validate.
- Name a concrete surface: Authentication, Dashboard, API client, Data layer,
  Repository, Form validation, Image upload, Error handling, CI workflow, README.
- No trailing period.
- Avoid empty titles like `update stuff`, `changes`, `fix bugs`,
  `improve project`, `misc`, `wip`.

Good: `feat: Implement child profile selector`,
`refactor: Move payment validation into service`,
`fix: Harden image upload validation`.

### 4. Write the body

Bullets starting with `- `, each beginning with an imperative verb and
describing one concrete change. Order them so the most important change reads
first:

1. Main implementation change.
2. Supporting structural changes.
3. Security, validation, or error-handling behavior.
4. Compatibility or preserved behavior.
5. Tests, build, lint, or manual validation (only if actually performed).
6. Documentation updates.

Length: 2 to 4 bullets for small commits, 4 to 9 for normal ones, up to about 10
for a large but coherent change. Every bullet must answer at least one of: what
was added, moved, extracted, protected, enforced, preserved, validated, or
documented. Drop any bullet the diff does not back up.

Full worked examples per project type (mobile, frontend, backend, scripts, CI,
docs) live in `references/examples.md`. Read that file when you want a concrete
template to adapt.

### 5. Check grouping before finalizing

Confirm the change set is coherent: the files support one goal, the title covers
the whole diff, and the body hides nothing unrelated. If the diff mixes
unrelated work, do not force it into one message; propose splitting it into
separate commits.

## Operating modes

**Proposal mode (default).** No project Git policy authorizes commits: inspect
the diff and propose a message, without staging or committing.

**Local checkpoint commit mode.** Only when the project Git policy or the user
explicitly allows a local commit. First confirm the work is complete, coherent,
free of secrets and unrelated files, and that validation either ran or is
clearly flagged as unverified. Then stage only the relevant files and commit:

```bash
git add <relevant-files>
git commit -m "<type>: <imperative title>" -m "- <actual change>" -m "- <actual change>"
```

Report the title and the validation result. Never push afterward unless asked.

## Output

Respond in the user's language (default Spanish for this user); keep commit
titles and bodies in English unless the user asks otherwise. Be brief: show the
commit, justify the type in a line, and state what you did not run.

````markdown
Listo. Con base en el diff actual, este seria el commit:

```text
<type>: <title>

- <actual change>
- <actual change>
- <test/docs/validation if actually run>
```

Tipo `<type>` porque <razon en una linea>.
No ejecute `git push` ni deploy.
````

When the diff contains unrelated changes, propose the split instead of one
message:

```markdown
Veo cambios que conviene separar en mas de un commit:

1. `<type>: <title>` — <scope>
2. `<type>: <title>` — <scope>

No ejecute `git push` ni deploy.
```

If validation was not run, say so plainly rather than implying it:
`No puedo confirmar tests porque no hay evidencia en la terminal ni en el diff.`
