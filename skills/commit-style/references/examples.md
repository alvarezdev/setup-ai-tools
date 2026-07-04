# Commit examples by project type

Use these only as style patterns. Replace feature names, layers, commands, and
validation steps with the actual repository context. Never copy a validation
bullet unless that validation actually ran.

## Mobile example

```text
feat: Implement child profile selector

- Add child selector widget with avatar and display name support
- Connect selected child state to the home screen controller
- Preserve empty state behavior when no children are available
- Validate navigation after changing the active child
- Document selector usage in the feature README
```

## Frontend web example

```text
feat: Create landing page hero section

- Add responsive hero layout for desktop and mobile breakpoints
- Create reusable call-to-action button component
- Move page copy into a local content configuration
- Preserve existing header and footer behavior
- Validate production build after the UI changes
```

## Backend example

```text
feat: Implement authenticated profile endpoint

- Add profile route for authenticated user reads
- Move profile lookup logic into a service
- Validate missing and invalid auth tokens before reading data
- Preserve existing response shape for API clients
- Add integration coverage for authorized and unauthorized requests
```

## Scripts or tooling example

```text
chore: Add local database reset script

- Add reset script for local development data
- Load environment variables from the local config file
- Prevent execution when production variables are detected
- Document reset usage and safety notes in the README
```

## CI example

```text
ci: Add pull request validation workflow

- Add workflow for pull request validation
- Install dependencies with the project package manager
- Run lint, tests, and build checks before merge
- Cache dependencies for faster repeated executions
- Document required checks in the contribution guide
```

## Docs example

```text
docs: Add architecture overview

- Document the main project layers and responsibilities
- Explain module boundaries with examples
- Add local development and testing commands
- Include notes for future contributors and coding agents
```
