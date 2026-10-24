import 'package:flutter_test/flutter_test.dart';
import 'package:houseowl/cubits/documents_cubit.dart';
import 'package:houseowl/enums/documents_filter_enum.dart';
import 'package:houseowl/models/document.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/services/transaction.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/document.dart';

import 'local_only_transaction_handler.dart';

Household household = Household(id: 1, name: "Test");

DateTime daysFromNow(int days) =>
    DateTime.now().toUtc().add(Duration(days: days));

final sampleDocuments = [
  Document(id: 1, title: "Passport", expiresAt: daysFromNow(-1)),
  Document(id: 2, title: "Insurance", expiresAt: daysFromNow(10)),
  Document(id: 3, title: "Warranty", expiresAt: daysFromNow(200)),
  Document(id: 4, title: "Lease"),
];

/// Serves the sample list for document get transactions so the online-only
/// cubit can be exercised without a backend.
class FakeTransactionHandler extends TransactionHandler {
  FakeTransactionHandler() : super.internal();

  @override
  Future<T> runTransaction<T>(Transaction<T> t,
      {bool forceOffline = false, bool saveTransaction = true}) {
    if (t is TransactionDocumentsGet) {
      return Future<List<Document>>.value(sampleDocuments) as Future<T>;
    }
    if (t is TransactionDocumentAdd) {
      return Future<bool>.value(true) as Future<T>;
    }

    return t.runLocal();
  }
}

void main() {
  DocumentsCubit createCubit() =>
      DocumentsCubit.forTesting(FakeTransactionHandler(), household);

  testWidgets("Refresh emits the document list", (tester) async {
    final cubit = createCubit();
    await cubit.refresh();

    expect(cubit.state, isA<ListDocumentsCubitState>());
    expect((cubit.state as ListDocumentsCubitState).documents, sampleDocuments);
    await cubit.close();
  });

  testWidgets("Expiring soon pins already-expired then soonest first",
      (tester) async {
    final cubit = createCubit();
    await cubit.refresh();

    final state = cubit.state as ListDocumentsCubitState;
    expect(
      state.expiringSoon.map((d) => d.title),
      ["Passport", "Insurance"],
    );
    await cubit.close();
  });

  testWidgets("Filter chips switch the requested expiry window",
      (tester) async {
    final cubit = createCubit();
    await cubit.refresh();

    cubit.setFilter(DocumentsFilter.month);
    await cubit.setFilter(DocumentsFilter.month);

    expect(cubit.filter, DocumentsFilter.month);
    expect(
        (cubit.state as ListDocumentsCubitState).filter, DocumentsFilter.month);
    await cubit.close();
  });

  testWidgets("Add runs through the transaction handler", (tester) async {
    final cubit = createCubit();
    await cubit.refresh();

    expect(
      await cubit.addDocument(const Document(id: 9, title: "New")),
      isTrue,
    );
    await cubit.close();
  });

  testWidgets("Local-only handler reports failure (online-only feature)",
      (tester) async {
    final cubit = DocumentsCubit.forTesting(
      LocalOnlyTransactionHandler(),
      household,
    );
    await cubit.refresh();

    expect(
      await cubit.addDocument(const Document(id: 9, title: "New")),
      isFalse,
    );
    expect(cubit.state, isA<ListDocumentsCubitState>());
    await cubit.close();
  });
}
