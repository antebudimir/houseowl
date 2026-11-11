# AGENTS.md

Orientation for agents landing in this repo. Conventions live in `.clinerules/`; this file is the map.

## What this is

HouseOwl — a hard fork of [KitchenOwl](https://github.com/TomBursch/kitchenowl) (upstream: grocery list + recipes), pivoted from grocery shopping to general household coordination.

- **Removed:** recipes, expenses, meal planner.
- **Added:** tasks, notes, events (attendees + overlap detection), persons/birthdays, planned buys, document vault (offline-cached), loyalty cards (bundled ML Kit, no Play Services), inline category and shopping-list management.

## Rebrand

- `kitchenowl` → `houseowl`: Dart package `houseowl`, Android app id `com.antebudimir.houseowl`, image `ghcr.io/antebudimir/houseowl`.
- The `kitchenowl/` **directory name is intentionally kept**. Do not rename it, and do not "fix" it in docs.
- User-visible strings say HouseOwl; internal identifiers (`KitchenOwlFab`, `KitchenOwlMarkdownBody`, …) stay as they are.

## Where things live

- `backend/` — Flask + SQLAlchemy + Alembic (`app/`, `migrations/`, `tests/`), plus the `manage.py` CLI.
- `kitchenowl/` — Flutter client (the directory is still called kitchenowl, see above): `lib/` app code, `lib/l10n/*.arb` translations, `lib/gen/` generated, `android/` `ios/` `linux/` `web/`.
- `docs/` — mkdocs site. `.github/workflows/` — CI/CD.

## Gates

- Backend: `uv run pytest` (in `backend/`).
- Client: `flutter gen-l10n`, `flutter analyze`, `flutter test`.
- Guards: `kitchenowl/scripts/check_theme_imports.sh` (no `package:flutter/material.dart`) and `! grep -Ei 'firebase|play-services' pubspec.lock`.

## Two non-negotiables

- **No feature flags.** Every shipped feature is unconditionally present. The upstream `planner_feature` / `expenses_feature` columns stay in the schema but are ignored — do not reintroduce gating.
- **Persons are external contacts; members are household accounts.** Assignment and ownership FKs point at users, never at persons.

## Audience split

- `README.md` (fork section) is written for people: user-facing changes only — no process meta-language, no links to this file or `.clinerules/`.
- `AGENTS.md` and `.clinerules/` are written for agents: conventions, gates, footguns. Keep the two audiences separate.

## Rules index

- `01-core-behavior.md` — how to work in this repo
- `02-code-quality.md` — Python/Dart expectations, tests, hygiene
- `03-workflow.md` — gates, commits, what never to commit
- `04-ux.md` — theming, states, offline, interaction, copy
- `05-git.md` — branch safety, commit style, tags
- `06-backend.md` — migrations, SQLite, test isolation, marshmallow
- `07-flutter-client.md` — imports, l10n, dependencies, offline queue
- `08-upstream-sync.md` — cherry-pick playbook and rebrand invariant
