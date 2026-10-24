import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/documents_cubit.dart';
import 'package:houseowl/models/document.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/pages/household_page/documents_page.dart';
import 'package:material_ui/material_ui.dart' as mui;

import '../cubits/local_only_transaction_handler.dart';
import 'package:houseowl/services/transaction.dart';
import 'package:houseowl/services/transactions/document.dart';

class StubTransactionHandler extends LocalOnlyTransactionHandler {
  final List<Document> documents;

  StubTransactionHandler(this.documents);

  @override
  Future<T> runTransaction<T>(Transaction<T> t,
      {bool forceOffline = false, bool saveTransaction = true}) {
    if (t is TransactionDocumentsGet) {
      return Future<List<Document>>.value(documents) as Future<T>;
    }

    return super.runTransaction<T>(t,
        forceOffline: forceOffline, saveTransaction: saveTransaction);
  }
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required List<Document> documents,
}) async {
  final household = Household(id: 1, name: "Test");
  final cubit = DocumentsCubit.forTesting(
    StubTransactionHandler(documents),
    household,
  );
  await tester.pumpWidget(
    BlocProvider<DocumentsCubit>.value(
      value: cubit,
      child: mui.MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const mui.Scaffold(body: DocumentsPage()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets("documents without expiry show no expiring-soon section",
      (tester) async {
    await _pumpPage(tester, documents: const [
      Document(id: 1, title: "Lease"),
    ]);

    expect(find.text("Expiring soon"), findsNothing);
    expect(find.text("Lease"), findsOneWidget);
  });

  testWidgets("expiring documents are pinned under the expiring-soon header",
      (tester) async {
    await _pumpPage(tester, documents: [
      Document(id: 1, title: "Lease"),
      Document(
          id: 2,
          title: "Passport",
          expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 1))),
      Document(
          id: 3,
          title: "Insurance",
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 10))),
    ]);

    expect(find.text("Expired"), findsOneWidget);
    // The header and the amber badge share the "Expiring soon" string.
    expect(find.text("Expiring soon"), findsNWidgets(2));
  });

  testWidgets("non-expiring documents show no badges", (tester) async {
    await _pumpPage(tester, documents: const [
      Document(id: 1, title: "Warranty"),
    ]);

    expect(find.text("Expired"), findsNothing);
  });
}
