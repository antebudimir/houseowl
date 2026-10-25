# Changelog

All notable changes to this fork of [KitchenOwl](https://github.com/TomBursch/kitchenowl)
are documented in this file, on top of upstream version 0.7.10.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and versioning follows [SemVer](https://semver.org/).

**Convention:** update `[Unreleased]` in the commit that completes a feature.
For multi-commit features, that's the final commit. For single-commit
features, that's the same commit.

## [Unreleased]
## [Unreleased]

- **Fix the "More" sheet on mobile.** Its view list used a hardcoded
  `skip(7)` (so Notes, Documents and Loyalty Cards were missing for
  households whose view ordering puts them before position 7) and every
  tile navigated to the household-switch screen instead of the view.
  The sheet now lists exactly the views not shown in the bottom bar
  (first four + More tab), and tapping a tile navigates to the view with
  the proper data refreshes, matching the drawer's behavior.
- Mobile bottom navigation showed only the first five views (upstream
  `take(5)`), hiding Tasks, Documents, Loyalty Cards, Events and anything
  added later. The bar now always shows the four leading views plus a
  "More" tab (house icon) that opens the More sheet listing every view;
  the "More" tab highlights when a non-visible view is open, fixing the
  out-of-range selected-index glitch when deep views were opened from the
  drawer.


- **Rebrand: KitchenOwl → HouseOwl.** Dart package renamed
  (`package:kitchenowl` → `package:houseowl`), backend API/branding, app
  identifiers (`com.tombursch.kitchenowl` → `com.antebudimir.houseowl`),
  Docker image names (`antebudimir/houseowl*`), docs, and user-facing strings.
  **Breaking / user-visible:**
  - Android: different application id — in-place upgrades from KitchenOwl are
    not possible; install fresh.
  - Images: compose files now pull `antebudimir/houseowl` /
    `antebudimir/houseowl-backend` / `antebudimir/houseowl-web`; named volumes
    renamed (`kitchenowl_*` → `houseowl_*`), so old volumes are not picked up
    automatically — migrate data manually if needed.
  - CI deploys build with **podman** (`podman build` + `podman manifest push`)
    instead of `docker/build-push-action`; self-hosting docs now use
    `podman compose up`. Compose file names are unchanged (`Dockerfile`,
    `docker-compose.yml`).
  - Env var: `HOUSEOWL_MCP_ENABLED` is the new name; the old
    `KITCHENOWL_MCP_ENABLED` still works (deprecated fallback).
  - OIDC: the custom-scheme flag is now `houseowl_scheme`; the backend still
    accepts `kitchenowl_scheme` from older clients, but the redirect scheme is
    now `houseowl:` — client apps must be updated together with the server.
  - Intentionally kept: the Flutter source directory is still `kitchenowl/`
    (renaming it would touch every path/CI reference for no user-visible
    benefit); the gitignored `ephemeral/` platform dirs regenerate.
- Marshmallow 4 silently ignores truthy-returning validators, so
  `_not_blank`-style validators were inert and blank strings were accepted for
  usernames, household names, item/task/note titles, etc.; validators now raise
  `ValidationError` (regression tests added).
- Verified the fresh-clone migration chain end to end: `flask db upgrade` on
  an empty database passes the full chain and downgrade works. (The SQLite FK
  issue in the remove-recipes-and-planner migration was already fixed in
  `c8d9e0a12b34`, which rebuilds `report` without `recipe_id` instead of a
  plain `DROP COLUMN`; no additional code change was needed — this moves the
  fresh-clone migration chain from known limitation to confirmed working.)

### Fixed

- The loyalty card barcode rendered black-on-black in dark mode (it inherited
  ambient theme colors); it now always renders black bars on a white
  container so it stays scannable in both themes

- Planned buy, task, and event add/edit pages (plus their list pages and the
  tag selector) rendered light in dark mode: they imported
  `package:flutter/material.dart`, whose `Theme.of` silently falls back to a
  light default under the material_ui-forked app; they now use the
  `material_ui` import like the document/note/loyalty/person pages
- Households created without a language silently ended up with zero default
  items (and therefore no item icons in search/suggestions): `importLanguage`
  raised "language not supported" for a null language; it now falls back to
  English defaults

### Changed

- Default-item attributes: the 13 default items that ship without an icon but
  have an exact-name match in the client icon font (chicken, turkey, wheat,
  noodles, wipes, squash, …) now get that icon; upstream's attributes.json is
  a stale periodic export of the official instance's icon consensus, so this
  intentionally diverges from upstream

### Fixed

- Flutter-material widgets (ListTile, InkWell, FilterChip, table_calendar, …)
  crashed with "No Material widget found" when hosted under the `material_ui`
  fork's Scaffold (whose `Material` is a different type): the app now provides
  a transparent Flutter `Material` above the navigator, and tooltip-hovered
  controls (tag selector "+", date-clear buttons) carry their own transparent
  `Material` because the tooltip `OverlayPortal` boundary hides ancestors
- The add-task page briefly flashed an error when opened with an assignee or
  buy link set: the assignee/buy dropdowns built a value with no matching item
  while their option lists were still loading (or a request failed); they now
  render empty items until data arrives and dedupe entries by id
- `GET /api/household/<id>/task` returned 500 on every call: the JSON provider
  serialized plain `date` values (e.g. task due dates) with
  `date.replace(tzinfo=...)`, which is unsupported; dates now encode as
  midnight-UTC epoch milliseconds (matching the person birthday handling)
- The note, task, and event add/edit pages crashed on open ("Looking up a
  deactivated widget's ancestor" / provider-not-found): their editor cubits are
  now provided by the pages themselves, and every add/edit push site injects
  the owning list cubit (tasks, persons, notes, planned buys, events) so saves
  update the list in place. Existing tags/attendees are preselected when
  editing
- The shopping list no longer flashes the loading skeleton when refreshing or
  switching back to an already known-empty list
- The household settings view editor now offers a visibility switch for every
  view (not just optional ones); the last active view can never be hidden (its
  switch is disabled and the backend rejects hiding all views)

### Changed

- Households gained a dedicated `hidden_views` column (migration
  `b8e4f2a7c9d1`); `ViewsEnum.isViewActive` now checks it instead of always
  returning true, and newly added views default to visible

### Added

- Documents Vault: a new "Documents" view lists household documents as tiles
  with title, filename, and expiry badges (red for expired, amber when
  expiring within 30 days). A pinned "Expiring soon" section (shown on the
  unfiltered list, sorted soonest-first, expired included) surfaces the
  time-sensitive entries. Add/edit page offers title, markdown notes, a
  clearable expiry date, a person contact from the household directory, and a
  file attachment uploaded via `/api/upload`. Filter chips narrow the list to
  entries expiring within 30 or 90 days, and search is server-backed.
  Online-only for v1 (no offline cache or queue); real-time updates via the
  `document:update` Socket.IO event
- Backend `Document` model (nullable `expires_at` indexed for expiry queries,
  `file_id → file.filename` attachment deleted alongside the document,
  `contact_id → person` with `SET NULL`), `/api/household/<id>/document`
  (list with `?search=` / `?expiring_within=30d|90d`, create) +
  `/api/document/<id>` (get/update/delete) endpoints, socket events, and MCP
  tools; migration `b2f8d5a6c9e1` (commits `7ac27bad`, `a1d5bf9d`)
- Document export/import: `GET /api/household/<id>/export/documents` returns
  a portable, self-contained export (no ids, ISO expiry, contact by name,
  file blob inlined as base64); the `/import` endpoint accepts a
  `documents` list, recreates file blobs, links contacts that already exist
  in the target household by name (never inventing person rows), and is
  idempotent on re-import (commit `d0559701`)
- Planned buys: a new "Planned" view (replacing the balances view slot in the
  household navigation) lists buys grouped into status sections — Idea,
  Planned, Ordered, Acquired — sorted by status, then target date (nulls
  last). Add/edit page offers a free-text category with autocomplete over the
  household's existing buy categories (`/planned_buy/categories`), a 0–3
  priority (low/normal/high/urgent), an optional assignee from the household
  people directory, an optional target date, and — once a buy is marked
  Acquired — an optional actual price
- `acquired_at` is server-stamped when a buy transitions to `acquired`
  (idempotent on re-acquire) and cleared when it moves back; the actual price
  is intentionally a plain nullable field on the buy rather than spawning a
  separate bookkeeping entity
- Real-time updates via the `planned_buy:update` Socket.IO event
- Backend `PlannedBuy` model (status enum idea/planned/ordered/acquired,
  nullable `assignee_id → person` with `SET NULL`, nullable `target_date`)
  and `/api/household/<id>/planned_buy` (list with `?status=` /
  `?assignee=me`, create) + `/api/planned_buy/<id>` (get/update/delete) +
  `/categories` endpoints, plus a smoke-tested migration `a7c3e91f40b2`
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
- Tasks: a new "Tasks" view lists open tasks (sorted by due date with nulls
  last, then priority) above a collapsed "completed" section. Add/edit page
  offers a description, a 0–3 priority, a due date (bare ISO calendar dates
  end to end — no timezone math), an optional assignee, an optional link to
  a non-acquired planned buy, and tag selection reusing the shared tag
  selector. Completing a task stamps `completed_at` and — for recurring
  tasks (daily/weekly/biweekly/monthly/yearly) — materializes exactly one
  successor, schedule-anchored from the original due date (overdue daily
  tasks catch up to tomorrow instead of spawning a burst) with
  month-length clamping that keeps the anchored day (Jan 31 monthly →
  Feb 28 → Mar 31). Completion is idempotent and does **not** touch the
  linked buy's status; advance the buy manually if desired
- Backend `Task` model (nullable `assignee_id` and `buy_id`, both
  `SET NULL`) with `TaskTags` join mirroring `NoteTags`; `Tag.merge()` now
  re-points task tags alongside note tags; `task:update` Socket.IO event;
  `/api/household/<id>/task` + `/api/task/<id>` endpoints; migration
  `e5b1c8d3f7a2` (smoke-tested up and down); MCP tools `list_tasks`,
  `create_task`, `complete_task`, `delete_task`; the MCP server docstring no
  longer advertises tools that don't exist (planned-buy MCP tools remain
  future scope)
- Events calendar: a new "Events" view with a month calendar (`table_calendar`)
  plus a per-day agenda (tap to edit, long-press to delete with
  confirmation), and an add/edit page with name, description, **location**
  (nullable, 256 chars — for concerts, kindergarten meetings, etc.), an
  all-day toggle, date/time pickers, and an attendee multi-select
- Multi-attendee conflict detection is **per person, via a join table**:
  an event double-books someone only if an *attendee* is already booked,
  so Mom and Dad can each have overlapping solo events but a family event
  conflicts on any shared person. Overlap uses half-open `[start, end)`
  intervals, so back-to-back events never conflict; events with no
  attendees are never blocked. Updates exclude the event itself
- The **server is authoritative**: creating/updating onto a conflict is
  hard-blocked with `409` + the conflicting events (race-safe), while the
  form additionally pre-checks via `GET …/event/conflicts` to show a live
  "Conflicts with *Dentist* — Mom, Dad" banner before saving
- Time handling: events are stored as UTC `DateTime` and serialized to
  epoch milliseconds by the shared JSON provider (no boundary conversion
  needed, unlike `Person.birthday`); the client sends and renders epoch ms
  in local time. All-day events store the UTC instants of the creator's
  local `[midnight, next midnight)` — a client-render flag, so the server
  never does timezone math
- Backend `Event` + `EventAttendee` models (composite-PK join; deleting a
  person cascades their attendance), `/api/household/<id>/event` (list with
  optional `?from`/`?to` ms range, create) + `/api/event/<id>`
  (get/update/delete) + `/conflicts`; `event:update` Socket.IO event;
  migration `f9d2a4b6c1e8` (smoke-tested up and down via the new
  `make smoke-migration` target, which also documents the `DB_NAME`
  (not `KITCHENOWL_DATABASE_URI`) gotcha); MCP tools `list_events`,
  `create_event` (conflicts surfaced as a `reason: conflict` result),
  `delete_event`

- Loyalty cards: a new "Loyalty Cards" view lists cards (name, note, barcode
  number) with a rendered barcode on the card page (`barcode_widget`, offline
  — no image fetch) and camera scanning of supported 1D/2D formats
  (`mobile_scanner`) on the add page. Barcode values are stored as strings
  alongside a format enum kept in sync with the backend's. Local offline
  cache + offline-queue transactions mirroring the other views; real-time
  updates via the `loyalty_card:update` Socket.IO event. Backend
  `LoyaltyCard` model, `/api/household/<id>/loyalty_card` +
  `/api/loyalty_card/<id>` endpoints, MCP tools, and export/import landed in
  commit `bf60e7db`
- Shopping list suggestions: the client fetches the backend's statistical
  suggestions (`GET /shoppinglist/<id>/suggested-items`, association rules +
  item frequency) concurrently with the list refresh, filters out items
  already on the list, caps at 6, and shows a "Suggestions" section above
  Recent (hidden while loading or empty); best-effort — offline it is simply
  absent
- Birthdays list rows show an "In {count} days" subtitle so entries outside
  the current year are meaningful at a glance

### Fixed

- Households whose stored `view_ordering` predates a newer view (or is empty)
  dropped the new view from the navigation, so opening it 404ed (first hit
  with loyalty cards): the nav now appends any views missing from the stored
  ordering, and the loyalty-card route uses the backend's camelCase
  `loyaltyCards` path
- Document attachment downloads now use `<title>.<original-extension>` as
  the filename (path separators sanitized, falling back to the stored
  filename when the title is empty) instead of the raw UUID blob name

### Known limitations
- Birthdays are list-only: there are no reminders/notifications for
  upcoming birthdays (backlog — a reminder pass would also want tasks/events
  integration)
- The checked-in `backend/database.db` is a stale development fixture, not
  the live database used by the dev stack (`/tmp/kowl-dev/database.db` per
  the dev `Makefile`/config); do not "fix" data issues against the fixture
  (a fresh clone from it also cannot replay the full migration chain — see
  the `remove_recipes` note below)
- SQLite is run with WAL enabled; a WAL/SHM sidecar can hold recently
  committed data until a checkpoint runs, so copying only `database.db` can
  lose the last transactions — checkpoint or copy all three files
- Note creation does not reject whitespace-only titles: the marshmallow
  `_not_blank` validator attached in the note schema is **inert** (it is never
  invoked by `validate_args`), so empty-titled notes can be stored. Deferred —
  fixing it belongs with the planned fork rebranding pass
- A **fresh SQLite clone cannot replay the full migration chain**: the
  `remove_recipes` migration fails with a foreign-key error when run from
  scratch (an existing database that already has the tables is unaffected).
  Deferred to the rebranding pass alongside a `make smoke-migration`-from-zero
  target
- `kitchenowl/lib/gen/l10n` (generated Flutter localizations) is gitignored;
  a fresh client clone must run `flutter gen-l10n --arb-dir=lib/l10n
  --output-dir=lib/gen/l10n --template-arb-file=app_en.arb
  --output-localization-file=app_localizations.dart --no-synthetic-package`
  (or `flutter run`/`flutter build`, which generate it implicitly) before the
  analyzer sees `AppLocalizations`. Wiring it into the build hook is deferred
  to the rebranding pass
- Events are **online-only** for v1 (no offline cache or queue), and the
  conflict check is a hard block rather than a warning — accepted for a
  family app. Deleting a person silently removes their attendance from
  events (the events themselves remain)
- Planned buys and tasks are **online-only** for v1 (no offline cache or
  queue). Intentional — the `MemStorage` transaction pattern is available if
  offline support is needed later
- On narrow screens the bottom navigation bar shows at most 5 entries
  (upstream `take(5)` behavior), so the new "People" and "Birthdays" views are
  **only reachable via the drawer / More view** on phones. Accepted for v1;
  revisit whether Birthdays should claim a bottom-nav slot over a less-used
  entry.

### Removed

- Expense system, end to end: backend `Expense`/`ExpensePaidFor`/
  `ExpenseCategory` models, expense endpoints, expense MCP tools
  (`list_expenses`/`create_expense`/`delete_expense`), balance recalculation
  service, `member.expense_balance`, household `expenses_feature` flag, and
  the client expense models, six cubits, pages (expense list, month list,
  overview, add/update, category management), charts, FAB, transactions, API
  service, expense sorting enum, `Member.balance`, import/export branches,
  and l10n keys. Migration `a7c3e91f40b2` drops `expense_paid_for` →
  `expense` → `expense_category` (child-first) and the two flag/balance
  columns; downgrade is not implemented
- Convert-to-expense on acquiring a planned buy: the planned buys view shows
  the `actual_price` directly on the acquired buy instead. With the expense
  system removed there is no expense entity left to convert into, and a
  one-field record did not justify keeping a second bookkeeping model alive
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

- Shopping-list renames now propagate in real time: the backend emits a
  `shoppinglist:update` Socket.IO event to the household room, and clients
  refresh on it (previously other clients waited for the 30s periodic refresh)
