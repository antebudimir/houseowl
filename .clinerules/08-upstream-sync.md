# Upstream Sync (KitchenOwl → HouseOwl)

HouseOwl is a hard fork of `TomBursch/kitchenowl`. The trees have diverged too far to merge: sync by **cherry-pick only**.

## Never

- Never use GitHub's "Sync fork" button.
- Never `git merge upstream/main`.
- Never rebase or force-push `main`.

## Before picking

```bash
git remote add upstream https://github.com/TomBursch/kitchenowl.git   # once per clone
git fetch upstream
git log --oneline --no-merges upstream/main ^HEAD
git branch backup/pre-upstream-sync-$(date +%F)
```

## Classify every candidate

- Skip commits touching removed features: recipes, recipe scraping/AI, expenses, meal planner, telemetry.
- Skip version-gate bumps unless the fork satisfies them — e.g. `da865b94` raised `MIN_BACKEND_VERSION` to 125 while the fork's backend reported 124.
- Treat dependency swaps and lockfile churn as high risk. A pick may be **partial**: `5b49c198` was taken for the `distinct_on` fix only, dropping the `psycopg2` → `psycopg[binary]` swap.
- Prefer bug, security, accessibility and UX fixes, plus docs that describe features this fork still has.
- If a picked commit depends on a skipped one, gate or inline the missing symbol **in the same commit** — e.g. `--send-terms-mail` gated with an explicit error until upstream `74374438` lands.

## Rebrand invariant

```bash
grep -rn "package:kitchenowl/" kitchenowl/lib/                       # must be empty
grep -rn "KitchenOwl" kitchenowl/lib/pages kitchenowl/lib/services    # internal names + attribution only
```

- Cleanly applied hunks still inject upstream import paths (`package:kitchenowl/gen/l10n/...`) and upstream doc links. Grep after **every** pick, not only after conflicts.
- Fix rebrand breakage inside the same commit as the pick; no follow-up "oops" commit.
- Upstream docs that describe removed features are rewritten for this fork or deleted. A doc that lists tools/endpoints the fork does not have must not land.

## Gates before push

1. Backend: `uv run pytest`.
2. `flutter gen-l10n`.
3. `flutter analyze`.
4. `flutter test`.
5. `bash scripts/check_theme_imports.sh` and the `firebase|play-services` lockfile guard.
6. CI green.
7. On-device smoke test for UI/background changes (offline queue flush after reconnect).

- Do not push `main` when the client gates cannot run locally; push a branch and let CI run them before merging.
- Test hygiene: if a test fails on a hardcoded date or environment assumption, fix the test. "Pre-existing and unrelated" is not a reason to ship a red suite.
