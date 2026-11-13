import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/widgets/reminder_picker.dart';
import 'package:material_ui/material_ui.dart' as mui;

Future<void> _pumpPicker(
  WidgetTester tester, {
  required int? value,
  required ValueChanged<int?> onChanged,
}) async {
  await tester.pumpWidget(
    mui.MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: mui.Scaffold(
        body: mui.Padding(
          padding: const EdgeInsets.all(16),
          child: ReminderPicker(value: value, onChanged: onChanged),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("defaults to no reminder and reports a chosen lead time",
      (tester) async {
    int? selected;
    var calls = 0;
    await _pumpPicker(
      tester,
      value: null,
      onChanged: (value) {
        selected = value;
        calls++;
      },
    );

    expect(find.text("No reminder"), findsOneWidget);

    await tester.tap(find.text("No reminder"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("1 hour before").last);
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(selected, 60);
  });

  testWidgets("reflects an existing reminder value", (tester) async {
    await _pumpPicker(tester, value: 1440, onChanged: (_) {});

    expect(find.text("1 day before"), findsOneWidget);
  });
}
