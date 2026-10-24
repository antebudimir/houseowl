#!/usr/bin/env bash
# CI guard: fail if any file under lib/ imports package:flutter/material.dart
# outside the allowlist. Pages/widgets must import package:material_ui instead,
# otherwise Theme.of silently falls back to Flutter's light ThemeData under
# the material_ui-forked app and dark mode breaks.
#
# Allowlist: lib/app.dart (deliberate mixed `as m` import for symbols
# material_ui does not re-export).

set -euo pipefail
cd "$(dirname "$0")/.."

ALLOWLIST=(
  "lib/app.dart"
)

violations=$(grep -rl --include='*.dart' "import 'package:flutter/material.dart'" lib/ || true)

status=0
for file in $violations; do
  allowed=false
  for a in "${ALLOWLIST[@]}"; do
    if [[ "$file" == "$a" ]]; then
      allowed=true
      break
    fi
  done
  if ! $allowed; then
    echo "ERROR: $file imports package:flutter/material.dart."
    echo "Import package:material_ui/material_ui.dart instead (see lib/app.dart for the only allowed exception)."
    status=1
  fi
done

if [[ $status -eq 0 ]]; then
  echo "OK: no disallowed flutter/material imports under lib/."
fi
exit $status
