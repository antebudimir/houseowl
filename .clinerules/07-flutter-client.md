# Flutter Client

## Imports and theming

- Import `package:material_ui/material_ui.dart`; never `package:flutter/material.dart`.
- `lib/app.dart` is the single allowlisted mixed-import exception (it needs `m.` symbols material_ui does not re-export). Do not add another.
- Enforced by `scripts/check_theme_imports.sh` and CI; run it locally after touching imports.

## Localisation

- `lib/gen/l10n/**` is generated and gitignored. Never hand-edit it; run `flutter gen-l10n` after changing any `.arb`.
- Add new keys to `app_en.arb` (and `app_en_AU.arb` when the string is identical); other locales fall back to English.
- Read strings via `AppLocalizations.of(context)!`; no hardcoded user-visible text.

## Gates

- `flutter analyze` and `flutter test` before every commit; `dart format` the files you touched.
- On a fresh clone run `flutter pub get` and `flutter gen-l10n` before the first build.

## Dependencies

- No Firebase, no Play Services. CI fails if `pubspec.lock` matches `firebase|play-services`.
- `mobile_scanner` stays on the bundled ML Kit model: `dev.steenbakker.mobile_scanner.useUnbundled=false` in `android/gradle.properties`. Do not remove that line.
- Do not bump `mobile_scanner` without re-checking that the property still applies.

## Offline write queue

- User-initiated mutations go through `TransactionHandler.runTransaction(..., saveTransaction: true)`; widgets do not call `ApiService` mutations directly.
- The queue is disk-backed in `transactions.json` (app support dir) and written atomically — temp file + `rename`, with `flush: true`. Keep it that way.
- Flushing must not abort on the first failure: per-transaction `try`/`catch`, keep the failing transaction, continue with the rest.
- `TransactionConflictException` means a permanent conflict: never requeue it. The flush drops it; call sites surface it with a localized snackbar (e.g. `itemAlreadyExists`).
- Transactions queued longer than 3 days are dropped at flush and reported through `App.notifyOfflineQueueExpired` → the global `App.scaffoldMessengerKey`.
