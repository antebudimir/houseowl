import 'package:houseowl/cubits/auth_cubit.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/services/storage/storage.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/shoppinglist.dart';

class BackgroundTask {
  static Future<void> run(AuthCubit authCubit) async {
    if (authCubit.getUser() != null) {
      await Future.wait([
        TransactionHandler.getInstance().runOpenTransactions(),
        PreferenceStorage.getInstance()
            .readInt(key: 'lastHouseholdId')
            .then((id) async {
          if (id != null)
            await TransactionHandler.getInstance().runTransaction(
                TransactionShoppingListGet(household: Household(id: id)));
        }),
      ]);
    }
  }
}
