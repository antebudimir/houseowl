# Code Quality

## Backend (Python, Flask)

- Type-hint new and changed functions. `pyright` and `ruff` are dev deps even though the CI lint step is commented out.
- Raise explicit errors: `ValidationError`, `NotFoundRequest`, `UnauthorizedRequest`. No bare `except:`.
- Keep controllers thin: validate → authorize → model → serialize. Reusable logic belongs in `backend/app/service/` or the model.
- Use the model API (`find_by_*`, `checkAuthorized()`, `save()`, `obj_to_dict()`) instead of ad-hoc queries in routes.
- Parameterize every query; never build SQL by string formatting.
- Put new env parsing in `app/config.py`; existing module-level reads (`service/mail.py`, `api/register_controller.py`) stay where they are.

## Client (Dart, Flutter)

- Null-safety and `const` by default; avoid `dynamic` outside JSON plumbing.
- One widget per concern; extract a widget when `build()` stops fitting on a screen.
- Every user-visible string comes from `AppLocalizations`; no literals in widgets.
- Mutations go through a cubit or `TransactionHandler`, not direct `ApiService` calls from `build()`.

## Tests

- Add tests with the change: API tests in `backend/tests/api/`, model tests in `backend/tests/model/`, widget tests in `kitchenowl/test/`.
- Test behaviour, not implementation: assert on responses and rendered widgets, not private fields.
- Derive expected values; never hardcode today's date, locale or timezone (`08-upstream-sync.md`).

## Hygiene

- No dead code, no commented-out blocks, no TODO without a tracked reason.
- Name things after the domain (`household`, `shoppinglist`, `plannedbuy`, `loyaltycard`), not after upstream's product.
- Keep the fork cherry-pickable: isolate fork-specific logic instead of editing shared upstream code in place.
