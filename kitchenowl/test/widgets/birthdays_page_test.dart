import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/persons_cubit.dart';
import 'package:houseowl/gen/l10n/app_localizations.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/pages/household_page/birthdays_page.dart';
import 'package:houseowl/services/storage/mem_storage.dart';
import 'package:material_ui/material_ui.dart' as mui;

import '../cubits/local_only_transaction_handler.dart';

Future<void> _pumpPage(
  WidgetTester tester, {
  List<Person> persons = const [],
}) async {
  final household = Household(id: 1, name: "Test");
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
        home: const mui.Scaffold(body: BirthdaysPage()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await cubit.close();
}

void main() {
  testWidgets("empty birthday list shows the empty state", (tester) async {
    await _pumpPage(tester);

    expect(find.byType(BirthdaysPage), findsOneWidget);
    expect(
      find.text("No birthdays yet.\nAdd a birthday to a person to see it here."),
      findsOneWidget,
    );
  });

  testWidgets("known birthday shows the upcoming person and their age",
      (tester) async {
    // Derive the expected age from the next occurrence rather than hardcoding
    // a year, so the test is stable across dates.
    final person = Person(
      id: 1,
      name: "Grandma",
      birthday: DateTime.utc(1950, 3, 10),
    );
    final next = person.nextBirthdayOccurrence()!;
    final expectedAge = next.year - 1950;

    await _pumpPage(tester, persons: [person]);

    expect(find.text("Grandma"), findsOneWidget);
    expect(find.text("Turns $expectedAge"), findsOneWidget);
  });
}
