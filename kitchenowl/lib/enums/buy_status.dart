import 'package:material_ui/material_ui.dart';
import 'package:kitchenowl/kitchenowl.dart';

enum BuyStatus {
  idea,
  planned,
  ordered,
  acquired;

  static BuyStatus parse(String str) {
    for (final status in BuyStatus.values) {
      if (status.name == str) return status;
    }

    return BuyStatus.idea;
  }

  String toLocalizedString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.buyStatusIdea,
      loc.buyStatusPlanned,
      loc.buyStatusOrdered,
      loc.buyStatusAcquired,
    ][index];
  }

  IconData toIcon() {
    return [
      Icons.lightbulb_outline_rounded,
      Icons.event_note_outlined,
      Icons.local_shipping_outlined,
      Icons.check_circle_outline_rounded,
    ][index];
  }
}
