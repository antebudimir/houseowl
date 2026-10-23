# Changelog

All notable changes to this fork of [KitchenOwl](https://github.com/TomBursch/kitchenowl)
are documented in this file, on top of upstream version 0.7.10.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and versioning follows [SemVer](https://semver.org/).

**Convention:** update `[Unreleased]` in the commit that completes a feature.
For multi-commit features, that's the final commit. For single-commit
features, that's the same commit.

## [Unreleased]

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

### Known limitations
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

### Changed

- Shopping-list renames now propagate in real time: the backend emits a
  `shoppinglist:update` Socket.IO event to the household room, and clients
  refresh on it (previously other clients waited for the 30s periodic refresh)
