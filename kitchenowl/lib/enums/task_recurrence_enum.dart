import 'package:material_ui/material_ui.dart';
import 'package:kitchenowl/kitchenowl.dart';

enum TaskRecurrence {
  none,
  daily,
  weekly,
  biweekly,
  monthly,
  yearly;

  static TaskRecurrence parse(String str) {
    for (final recurrence in TaskRecurrence.values) {
      if (recurrence.name == str) return recurrence;
    }

    return TaskRecurrence.none;
  }

  String toLocalizedString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.taskRecurrenceNone,
      loc.taskRecurrenceDaily,
      loc.taskRecurrenceWeekly,
      loc.taskRecurrenceBiweekly,
      loc.taskRecurrenceMonthly,
      loc.taskRecurrenceYearly,
    ][index];
  }
}
