# Backend (Flask, SQLAlchemy, Alembic)

## Migrations

- Any model change needs an Alembic revision in `backend/migrations/versions/`. A model edit without one is a bug, not a shortcut.
- Never edit an applied migration. Fix forward with a new revision.
- Verify every migration both ways before pushing:
  - Fresh empty DB: replay the whole chain base → head, then confirm the resulting schema actually has the new column/table.
  - Existing-schema DB: upgrade from the previous head, then exercise the changed feature.
- `entrypoint.sh` runs `flask db upgrade` only. On an empty DB that replays the old chain and rebuilds the *old* schema — deleting the database is not a migration test.
- Keep one head: `flask db heads` prints exactly one revision and `flask db history` reaches it.
- Column changes on SQLite go through batch mode. `render_as_batch=True` is set on `Migrate(...)` in `backend/app/config.py`; use `op.batch_alter_table` for anything SQLite cannot alter in place.

## SQLite

- WAL mode is enabled on connect (`app/config.py`).
- Never `cp` a live database. Take a consistent snapshot with `sqlite3 <db> ".backup '<copy>'"`.

## Tests

- `backend/tests/__init__.py` points `DB_NAME` at a throwaway directory before the app is imported.
- Never run pytest against the dev database; fixtures drop tables, so the test DB must be disposable.
- API tests live in `backend/tests/api/`, model tests in `backend/tests/model/`.

## Validation

- Marshmallow validators must `raise ValidationError(...)`. A validator that merely returns a truthy/falsy value is silently ignored by marshmallow 4.x.
- Validate in `schemas.py`, authorize in the controller (`checkAuthorized()`), and never trust a client-supplied id for ownership.

## Deployment config

- Env vars and protocol strings (OIDC/deep-link schemes) are deployment config: rename with a fallback shim, never hard-rename.
- Existing example: `HOUSEOWL_MCP_ENABLED` falling back to `KITCHENOWL_MCP_ENABLED` in `api/register_controller.py`.
- The fork ignores `planner_feature` / `expenses_feature`: they stay in the schema (migration `6c669d9ec3bd`) but are not mapped in the model and must not gate anything.
