import 'package:material_ui/material_ui.dart';
import 'package:houseowl/kitchenowl.dart';

/// A dropdown for choosing a reminder lead time, shared by the event and
/// task forms. Values are minutes before the start / due date; `null` means
/// no reminder. The fixed option set keeps the copy simple and translatable.
class ReminderPicker extends StatelessWidget {
  /// Minutes-before values offered by the picker, in display order.
  static const List<int?> options = <int?>[null, 0, 15, 60, 1440, 10080];

  final int? value;
  final ValueChanged<int?> onChanged;

  const ReminderPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static String labelFor(BuildContext context, int? minutes) {
    final loc = AppLocalizations.of(context)!;
    switch (minutes) {
      case null:
        return loc.reminderNone;
      case 0:
        return loc.reminderAtTime;
      case 15:
        return loc.reminder15Min;
      case 60:
        return loc.reminder1Hour;
      case 1440:
        return loc.reminder1Day;
      case 10080:
        return loc.reminder1Week;
      default:
        return loc.reminderNone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return DropdownButtonFormField<int?>(
      // Remount when the value changes so an externally set value (e.g. when
      // editing) is reflected rather than the stale initial selection.
      key: ValueKey<int?>(value),
      initialValue: value,
      decoration: InputDecoration(
        labelText: loc.reminder,
        prefixIcon: const Icon(Icons.notifications_outlined),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem<int?>(
            value: option,
            child: Text(labelFor(context, option)),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
