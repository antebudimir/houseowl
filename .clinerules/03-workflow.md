# Workflow

## Gates, in order

```bash
# 1. backend
cd backend && uv sync --all-extras --dev && uv run pytest

# 2. client
cd kitchenowl
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
bash scripts/check_theme_imports.sh
! grep -Ei 'firebase|play-services' pubspec.lock
```

- Run the narrowest failing test first (`pytest tests/api/test_api_task.py -k <name>`, `flutter test test/<path>`), then the full suite before push.
- CI mirrors these gates: `Pytesting` (backend), `Quality` (client + both guards), `CI deploy image (ghcr)` (image rebuild).
- No local Flutter SDK: do not push `main`; push a branch and let CI run the client gates first.

## Commits

- One logical change per commit. A cherry-pick stays one commit; fold its rebrand fixes in (`08-upstream-sync.md`).
- Prefix fork commits: `feat:`, `fix:`, `fix(area):`, `chore:`, `docs:`, `test:`.
- Update `CHANGELOG.md` `[Unreleased]` in the commit that completes a feature — the final commit of a multi-commit feature, the same commit for a single-commit feature.
- Update `docs/` in the same commit when behaviour, CLI flags or env vars change.

## Never commit

- `kitchenowl/lib/gen/**` (generated, gitignored), `build/`, `.dart_tool/`, `.venv/`, `__pycache__/`, `*.db`, `.env`.
- A model change without its migration (`06-backend.md`).
- Anything you have not run the gates against.

## When stuck

- Reproduce with the smallest command, then read the actual error.
- Check whether the feature you are debugging was removed by the fork (`AGENTS.md`).
- Report the blocker with the exact command and output instead of guessing.
