import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/notes_cubit.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/note.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/household_page/notes_page.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:material_ui/material_ui.dart' as mui;

import '../cubits/local_only_transaction_handler.dart';

Future<void> _pumpPage(
  WidgetTester tester, {
  List<Note> notes = const [],
}) async {
  final household = Household(id: 1, name: "Test");
  // Seed the in-memory cache so the cubit's initial load never touches
  // file IO, whose plugin futures never complete in the test FakeAsync zone.
  MemStorage.getInstance().writeNotes(household, notes);
  final cubit = NotesCubit.forTesting(
    LocalOnlyTransactionHandler(),
    household,
  );
  await tester.pumpWidget(
    BlocProvider<NotesCubit>.value(
      value: cubit,
      child: mui.MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const mui.Scaffold(body: NotesPage()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await cubit.close();
}

void main() {
  testWidgets("empty note list shows the empty state", (tester) async {
    await _pumpPage(tester);

    expect(find.byType(NotesPage), findsOneWidget);
    expect(
      find.text("No notes yet.\nUse the plus button to add one."),
      findsOneWidget,
    );
  });

  testWidgets("notes render title, plain-text preview and open the detail page",
      (tester) async {
    await _pumpPage(tester, notes: const [
      Note(
        id: 1,
        title: "Wi-Fi",
        body: "Password: **hunter2**",
        tags: [Tag(name: "house")],
      ),
    ]);

    expect(find.text("Wi-Fi"), findsOneWidget);
    // Markdown syntax is stripped from the list preview.
    expect(find.text("Password: hunter2"), findsOneWidget);

    await tester.tap(find.text("Wi-Fi"));
    await tester.pumpAndSettle();

    // The detail page renders the markdown body.
    expect(find.byType(KitchenOwlMarkdownBody), findsOneWidget);
    expect(find.text("house"), findsOneWidget);
  });
}
