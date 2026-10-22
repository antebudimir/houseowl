# Changelog

All notable changes to this fork of [KitchenOwl](https://github.com/TomBursch/kitchenowl)
are documented in this file, on top of upstream version 0.7.10.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and versioning follows [SemVer](https://semver.org/).

**Convention:** update `[Unreleased]` in the commit that completes a feature.
For multi-commit features, that's the final commit. For single-commit
features, that's the same commit.

## [Unreleased]

### Added

- Household notes: a new "Notes" view lists notes with a debounced
  server-backed search (SQL `ILIKE` over title and body), full markdown body
  rendering on the note page, and add/edit pages with tag selection reusing
  the shared tag selector extracted from the recipe editor
- `Note` model with JSON roundtrip (tags travel as names on write and as tag
  objects on read), note local cache (`<household-id>-notes.json`) mirroring
  the other offline caches, and offline-queue transactions for
  add/update/delete; note search falls back to a local title/body filter when
  offline
- Real-time updates via the `note:update` Socket.IO event
- Backend `Note` + `NoteTags` models (reusing the household-scoped `Tag`
  vocabulary, so one tag can label both recipes and notes),
  `/api/household/<id>/note` + `/api/note/<id>` endpoints, and migration
  `b7e2f4a91c03` (commit `e3ac8a60`)
- Household people directory: a new "People" view lists household persons
  (name, role, birthday, phone, email, notes) with add, edit, and delete
  (delete asks for confirmation), local-first offline support, and real-time
  updates via the `person:update` Socket.IO event
- Dedicated "Birthdays" view sorted by next occurrence; birthdays stored
  without a year (backend sentinel 1990-01-01) are shown without a year
- Person local cache (`<household-id>-persons.json`) mirroring the other
  offline caches, plus offline-queue transactions for add/update/delete
- Backend household `Person` model and `/api/household/<id>/person` +
  `/api/person/<id>` endpoints (commit `8eacc2e8`)

### Known limitations

- On narrow screens the bottom navigation bar shows at most 5 entries
  (upstream `take(5)` behavior), so the new "People" and "Birthdays" views are
  **only reachable via the drawer / More view** on phones. Accepted for v1;
  revisit whether Birthdays should claim a bottom-nav slot over a less-used
  entry.

### Removed

- Recipe feature, end to end: backend `Recipe`/`RecipeItems`/`RecipeTags`/
  `RecipeHistory` models, recipe + scraper + discover endpoints, recipe MCP
  tools, recipe scraping/suggestion jobs and services, and the client recipe
  models, cubits, pages, widgets, transactions, offline caches, router routes,
  and l10n keys. Includes the tag cleanup this unblocked: `Tag` no longer
  carries a recipe branch (`RecipeTags` gone; `Tag.merge()` now only re-points
  note tags), and `Note.fromJson` no longer dual-accepts tag-name strings —
  the server always returns full tag objects. Migration `c8d9e0a12b34` drops
  the recipe tables.
- Meal planner, together with the recipes it structurally depends on
  (`Planner.recipe_id` is a primary-key FK to `recipe.id`): backend planner
  model/endpoints/MCP tools, household `planner_feature` flag, and the client
  planner page, cubit, transactions, cache, and `ViewsEnum.planner` entry.
  The queued planner TZ fix is moot — the planner is gone; Events (Phase 4)
  will not reuse it.
- Recipe-based reports (`report.recipe_id` + navigation) and the "used in
  recipes" section on the item page; reports are now user reports only.
  Recipe/planner export & import branches and the recipe-link deep redirect
  and share-handler scrape route went with them.

### Changed

- Inline shopping-list management from the main-view header: add, rename, and
  delete lists via the add field and a long-press action sheet (rename is
  available for every list; delete only for non-default lists)
- `isDefault` flag on the shopping-list client model and API responses; list
  deletion is gated on it, falling back to treating the first list as the
  default when the server does not send the flag
- Error snackbar when shopping-list deletion fails

### Changed

- Shopping-list renames now propagate in real time: the backend emits a
  `shoppinglist:update` Socket.IO event to the household room, and clients
  refresh on it (previously other clients waited for the 30s periodic refresh)
