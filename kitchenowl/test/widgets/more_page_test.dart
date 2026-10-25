import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/app.dart';
import 'package:houseowl/cubits/auth_cubit.dart';
import 'package:houseowl/cubits/household_cubit.dart';
import 'package:houseowl/enums/views_enum.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/pages/household_page/more.dart';
import 'package:material_ui/material_ui.dart' as mui;

class _NoRefreshHouseholdCubit extends HouseholdCubit {
  _NoRefreshHouseholdCubit(Household household) : super(household);

  @override
  Future<void> refresh() async {}
}

/// MorePage reads App.isOffline, which requires the App singleton.
void _initApp() {
  App();
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required Household household,
  required void Function(BuildContext, ViewsEnum) onPageSelected,
}) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: AuthCubit()),
        BlocProvider<HouseholdCubit>.value(
          value: _NoRefreshHouseholdCubit(household),
        ),
      ],
      child: mui.MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: mui.Scaffold(
          body: MorePage(onPageSelected: onPageSelected),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets("MorePage lists all views beyond the four visible tabs",
      (tester) async {
    _initApp();
    // Ordering matching the user report: notes, documents and loyalty cards
    // sit at positions 4-6, tasks/events/more at 7-9.
    final household = Household(
      id: 1,
      name: "Amsterdam",
      viewOrdering: const [
        ViewsEnum.items,
        ViewsEnum.planned,
        ViewsEnum.persons,
        ViewsEnum.birthdays,
        ViewsEnum.notes,
        ViewsEnum.documents,
        ViewsEnum.loyaltyCards,
        ViewsEnum.tasks,
        ViewsEnum.events,
        ViewsEnum.more,
      ],
    );

    await _pumpPage(tester, household: household, onPageSelected: (_, __) {});

    // Views beyond the four visible tabs are listed.
    expect(find.text("Notes"), findsOneWidget);
    expect(find.text("Documents"), findsOneWidget);
    expect(find.text("Loyalty Cards"), findsOneWidget);
    expect(find.text("Tasks"), findsOneWidget);
    expect(find.text("Events"), findsOneWidget);

    // The four visible bottom-bar views and 'more' itself are not listed.
    expect(find.text("Shopping list"), findsNothing);
    expect(find.text("Planned"), findsNothing);
    expect(find.text("People"), findsNothing);
    expect(find.text("Birthdays"), findsNothing);
    expect(find.text("More"), findsNothing);
  });

  testWidgets("tapping a view tile invokes the page-selected callback",
      (tester) async {
    _initApp();
    final household = Household(id: 1, name: "Test");
    final List<ViewsEnum> tapped = [];

    await _pumpPage(
      tester,
      household: household,
      onPageSelected: (_, view) => tapped.add(view),
    );

    await tester.tap(find.text("Tasks"));
    await tester.pump();

    expect(tapped, [ViewsEnum.tasks]);
  });
}
