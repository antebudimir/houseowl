import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

/// Expiry-window filter chips shown on the documents page.
enum DocumentsFilter {
  all,
  month,
  quarter;

  int? get days {
    switch (this) {
      case DocumentsFilter.month:
        return 30;
      case DocumentsFilter.quarter:
        return 90;
      case DocumentsFilter.all:
        return null;
    }
  }

  String toLocalizedString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.documentsFilterAll,
      loc.documentsFilter30Days,
      loc.documentsFilter90Days,
    ][index];
  }
}
