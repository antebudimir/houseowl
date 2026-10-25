import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/persons_cubit.dart';
import 'package:houseowl/gen/l10n/app_localizations.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/pages/household_page/persons_page.dart';
import 'package:houseowl/services/storage/mem_storage.dart';
import 'package:material_ui/material_ui.dart' as mui;

import '../cubits/local_only_transaction_handler.dart';

Future<void> _pumpPage(
  WidgetTester tester, {
  List<Person> persons = const [],
}) async {
  final household = Household(id: 1, name: "Test");
  // Seed the in-memory cache so the cubit's initial load never touches
  // file IO, whose plugin futures never complete in the test FakeAsync zone.
  MemStorage.getInstance().writePersons(household, persons);
  final cubit = PersonsCubit.forTesting(
    LocalOnlyTransactionHandler(),
    household,
  );
  await tester.pumpWidget(
    BlocProvider<PersonsCubit>.value(
      value: cubit,
      child: mui.MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const mui.Scaffold(body: PersonsPage()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await cubit.close();
}

void main() {
  testWidgets("empty person list shows the empty state", (tester) async {
    await _pumpPage(tester);

    expect(find.byType(PersonsPage), findsOneWidget);
    expect(find.text("No people yet.\nUse the plus button to add someone."),
        findsOneWidget);
  });

  testWidgets("person without birthday is listed", (tester) async {
    await _pumpPage(
      tester,
      persons: const [Person(name: "No Birthday")],
    );

    expect(find.text("No Birthday"), findsOneWidget);
  });
}