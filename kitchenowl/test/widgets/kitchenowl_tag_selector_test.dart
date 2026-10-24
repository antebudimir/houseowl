import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:material_ui/material_ui.dart' as mui;

void main() {
  testWidgets(
    "hovering the add-tag button does not lose its Material ancestor",
    (tester) async {
      await tester.pumpWidget(
        mui.MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: mui.Scaffold(
            body: KitchenOwlTagSelector(
              tags: {
                const Tag(id: 1, name: "Tag"),
                const Tag(id: 2, name: "Other")
              },
              selectedTags: const {},
              onSelect: (_, __) {},
              onAdd: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Simulate a desktop mouse hovering over the add-tag button, which
      // triggers the Tooltip. The tooltip hosts its child inside an
      // OverlayPortal (a LookupBoundary), so the InkWell needs its own
      // Material ancestor or this hover throws.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.ancestor(
          of: find.byIcon(Icons.add),
          matching: find.byType(mui.InkWell))));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
