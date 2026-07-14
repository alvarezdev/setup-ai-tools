# AGENTS.md Template for Target Projects

Use this template in the blueprint's agent-instructions section. Fill every
placeholder; keep the generated file under 120 lines and make it executable by
an agent without prior conversation context.

```markdown
# {Project Name}

{One-line product description.}

## Commands

- `{package-manager} dev` — development server
- `{package-manager} build` — production build
- `{package-manager} lint` — static checks
- `{package-manager} test` — automated tests

## Stack

{Framework} + {language} + {styling} + {database} + {auth} + {hosting}

## Architecture

{Data flow, key directories, boundaries, and integration contracts.}

## Code Rules

1. {Specific, testable rule.}
2. {Specific, testable rule.}
3. {Specific, testable rule.}

## Design System

{Concrete colors, typography, spacing, and component guidance.}

## Environment Variables

| Variable | Purpose |
| --- | --- |
| `{VAR}` | {description} |

## Verification

{Commands and acceptance checks required before declaring work complete.}
```
