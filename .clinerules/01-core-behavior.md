# Core Behavior

Applies to every task. Fork invariants: `06`–`08`. Gates: `03-workflow.md`.

## Orient first

- Read `AGENTS.md` before your first edit: what this fork removed matters as much as what it added.
- Read the target file and its callers; grep for a sibling implementation before inventing a pattern.
- Check `git log --oneline -15` and `git status` before touching anything.
- State the plan when a task spans more than one file.

## Change minimally

- Make the smallest diff that solves the problem. No drive-by refactors, renames or reformatting.
- Match the surrounding code: naming, error handling, widget structure, test layout.
- Reuse existing helpers and widgets; do not add a second way to do the same thing.
- Do not add dependencies, env vars, config keys or public API surface without a concrete need.
- Never hand-edit generated or vendored files (`kitchenowl/lib/gen/**`, lockfiles, build output).

## Verify

- Prove behaviour with a test or real command output, not by reading code.
- Run the gates in `03-workflow.md`; if a gate cannot run here, say so explicitly.
- Fix a failing test or explain precisely why it is unrelated — never leave the suite red.

## Guardrails

- Never commit secrets, tokens, personal data or real household content.
- Never hard-rename deployment identifiers (env vars, deep-link schemes, image names); add a fallback shim (`06-backend.md`).
- Ask before irreversible calls: schema changes, public API shape, branding, licensing.
- Do not reintroduce removed features (recipes, expenses, meal planner) to satisfy a request; propose a fork-shaped alternative instead.
