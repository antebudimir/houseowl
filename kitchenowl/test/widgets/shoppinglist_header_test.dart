import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/gen/l10n/app_localizations.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/widgets/shopping_list/shoppinglist_header.dart';
import 'package:material_ui/material_ui.dart' as mui
    show AlertDialog, MaterialApp, Scaffold, TextField;

Future<void> _pumpHeader(
  WidgetTester tester, {
  required List<ShoppingList> shoppinglists,
  int? selectedShoppinglistId,
  required ValueChanged<String> onAdd,
  required ValueChanged<ShoppingList> onDelete,
}) async {
  await tester.pumpWidget(
    mui.MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: mui.Scaffold(
        body: ShoppinglistHeader(
          shoppinglists: shoppinglists,
          selectedShoppinglistId: selectedShoppinglistId,
          onSelect: (_) {},
          onAdd: (name) async => onAdd(name),
          onDelete: (shoppinglist) async {
            onDelete(shoppinglist);
            return true;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final defaultList = ShoppingList(id: 1, name: "Default", isDefault: true);
  final otherList = ShoppingList(id: 2, name: "Other", isDefault: false);

  testWidgets("add chip opens inline field and submits trimmed name",
      (tester) async {
    final added = <String>[];
    await _pumpHeader(
      tester,
      shoppinglists: [defaultList],
      onAdd: added.add,
      onDelete: (_) {},
    );

    expect(find.byType(mui.TextField), findsNothing);
    await tester.tap(find.text("Add shopping list"));
    await tester.pumpAndSettle();
    expect(find.byType(mui.TextField), findsOneWidget);

    await tester.enterText(find.byType(mui.TextField), "  Groceries  ");
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(added, ["Groceries"]);
    // Field reverted to the idle add chip.
    expect(find.byType(mui.TextField), findsNothing);
  });

  testWidgets("cancel via tap outside reverts and does not call onAdd",
      (tester) async {
    final added = <String>[];
    await _pumpHeader(
      tester,
      shoppinglists: [defaultList],
      onAdd: added.add,
      onDelete: (_) {},
    );

    await tester.tap(find.text("Add shopping list"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(mui.TextField), "Nope");

    // Tap far outside the field to cancel.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // The field must be gone (idle chip restored), not just the API untouched.
    expect(find.byType(mui.TextField), findsNothing);
    expect(find.text("Add shopping list"), findsOneWidget);
    expect(added, isEmpty);

    // Re-opening must not submit the stale text on cancel.
    await tester.tap(find.text("Add shopping list"));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(mui.TextField), findsNothing);
    expect(added, isEmpty);
  });

  testWidgets("delete is hidden on the default list but shown on others",
      (tester) async {
    final deleted = <ShoppingList>[];
    await _pumpHeader(
      tester,
      shoppinglists: [defaultList, otherList],
      selectedShoppinglistId: 1,
      onAdd: (_) {},
      onDelete: deleted.add,
    );

    await tester.longPress(find.text("Default"));
    await tester.pumpAndSettle();
    expect(find.byType(mui.AlertDialog), findsNothing);

    await tester.longPress(find.text("Other"));
    await tester.pumpAndSettle();
    expect(find.byType(mui.AlertDialog), findsOneWidget);

    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();
    expect(deleted.map((e) => e.id), [2]);
  });

  testWidgets("cancelling the confirmation does not delete", (tester) async {
    final deleted = <ShoppingList>[];
    await _pumpHeader(
      tester,
      shoppinglists: [defaultList, otherList],
      selectedShoppinglistId: 1,
      onAdd: (_) {},
      onDelete: deleted.add,
    );

    await tester.longPress(find.text("Other"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(deleted, isEmpty);
  });

  testWidgets("without the flag the first list is treated as the default",
      (tester) async {
    final deleted = <ShoppingList>[];
    final first = ShoppingList(id: 1, name: "First");
    final second = ShoppingList(id: 2, name: "Second");
    await _pumpHeader(
      tester,
      shoppinglists: [first, second],
      selectedShoppinglistId: 1,
      onAdd: (_) {},
      onDelete: deleted.add,
    );

    await tester.longPress(find.text("First"));
    await tester.pumpAndSettle();
    expect(find.byType(mui.AlertDialog), findsNothing);

    await tester.longPress(find.text("Second"));
    await tester.pumpAndSettle();
    expect(find.byType(mui.AlertDialog), findsOneWidget);
    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();
    expect(deleted.map((e) => e.id), [2]);
  });

  testWidgets("single list header still renders chips and add affordance",
      (tester) async {
    await _pumpHeader(
      tester,
      shoppinglists: [defaultList],
      onAdd: (_) {},
      onDelete: (_) {},
    );

    expect(find.text("Default"), findsOneWidget);
    expect(find.text("Add shopping list"), findsOneWidget);
  });
}
