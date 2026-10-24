import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/cubits/loyalty_cards_cubit.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:kitchenowl/services/transaction.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/loyalty_card.dart';

Household household = Household(id: 1, name: "Test");

final sampleCards = [
  LoyaltyCard(id: 1, storeName: "SuperMart", cardNumber: "4006381333931"),
  LoyaltyCard(id: 2, storeName: "Kiosk", cardNumber: "42"),
];

/// Serves the sample list for loyalty card get transactions so the
/// online-only cubit can be exercised without a backend.
class FakeTransactionHandler extends TransactionHandler {
  FakeTransactionHandler() : super.internal();

  @override
  Future<T> runTransaction<T>(Transaction<T> t,
      {bool forceOffline = false, bool saveTransaction = true}) {
    if (t is TransactionLoyaltyCardsGet) {
      return Future<List<LoyaltyCard>>.value(sampleCards) as Future<T>;
    }
    if (t is TransactionLoyaltyCardAdd) {
      return Future<bool>.value(true) as Future<T>;
    }
    if (t is TransactionLoyaltyCardRemove) {
      return Future<bool>.value(true) as Future<T>;
    }

    return t.runLocal();
  }
}

void main() {
  LoyaltyCardsCubit createCubit() =>
      LoyaltyCardsCubit.forTesting(FakeTransactionHandler(), household);

  testWidgets("Refresh emits the card list", (tester) async {
    final cubit = createCubit();
    await cubit.refresh();

    expect(cubit.state, isA<ListLoyaltyCardsCubitState>());
    expect(cubit.state.cards, sampleCards);
    await cubit.close();
  });

  testWidgets("Search emits a search state", (tester) async {
    final cubit = createCubit();
    await cubit.refresh();
    await cubit.search("kiosk");

    expect(cubit.state, isA<SearchLoyaltyCardsCubitState>());
    expect((cubit.state as SearchLoyaltyCardsCubitState).query, "kiosk");
    await cubit.close();
  });

  testWidgets("Clearing the search returns to the full list", (tester) async {
    final cubit = createCubit();
    await cubit.refresh();
    await cubit.search("kiosk");
    await cubit.refresh(null);

    expect(cubit.state, isA<ListLoyaltyCardsCubitState>());
    expect(cubit.state.cards, sampleCards);
    await cubit.close();
  });
}
