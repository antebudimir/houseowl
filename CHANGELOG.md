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
- Meal-plan `cooking_date` is truncated to a local-time date before storage
  (`backend/app/controller/planner_controller.py`), so in non-UTC timezones
  the stored date can shift by a day. Real upstream TZ bug; to be fixed with
  a UTC-normalizing one-liner **before Phase 4 (Events)**, which is calendar-
  adjacent.

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
