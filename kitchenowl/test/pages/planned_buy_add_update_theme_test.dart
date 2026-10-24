import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/planned_buys_cubit.dart';
import 'package:houseowl/gen/l10n/app_localizations.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/pages/household_page/planned_buy_add_update_page.dart';

import 'package:material_ui/material_ui.dart' as mui;

import '../cubits/local_only_transaction_handler.dart';

/// Regression test: pages must resolve the ambient material_ui theme, not
/// fall back to Flutter's light ThemeData.fallback() (the fallback happens
/// when a page uses flutter/material widgets whose Theme.of cannot find the
/// material_ui Theme installed by the app's material_ui MaterialApp).
void main() {
  testWidgets(
    "planned buy add page renders with the dark theme",
    (tester) async {
      final household = Household(id: 1, name: "Test");
      final cubit = PlannedBuysCubit.forTesting(
        LocalOnlyTransactionHandler(),
        household,
      );
      await tester.pumpWidget(
        BlocProvider<PlannedBuysCubit>.value(
          value: cubit,
          child: mui.MaterialApp(
            theme: mui.ThemeData.from(
              colorScheme: mui.ColorScheme.fromSeed(
                seedColor: mui.Colors.green,
                brightness: mui.Brightness.dark,
              ),
              useMaterial3: true,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const mui.Locale('en'),
            home: BlocProvider<PlannedBuysCubit>.value(
              value: cubit,
              child: PlannedBuyAddUpdatePage(household: household),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The Scaffold's Material carries the resolved scaffold background.
      final material = tester.widget<mui.Material>(
        find
            .descendant(
              of: find.byType(mui.Scaffold),
              matching: find.byType(mui.Material),
            )
            .first,
      );
      expect(material.color, isNotNull);
      expect(
        material.color!.computeLuminance(),
        lessThan(0.5),
        reason: "page background must be dark, not the light fallback",
      );
      await cubit.close();
    },
  );
}
