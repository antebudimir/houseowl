import 'package:houseowl/app.dart';
import 'package:houseowl/services/transaction.dart';
import 'package:houseowl/services/transaction_conflict_exception.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/storage/transaction_storage.dart';

class TransactionHandler {
  static TransactionHandler? _instance;

  TransactionHandler.internal();

  static TransactionHandler getInstance() {
    _instance ??= TransactionHandler.internal();

    return _instance!;
  }

  Future<void> runOpenTransactions() async {
    if (ApiService.getInstance().isConnected()) {
      List<Transaction> transactions =
          await TransactionStorage.getInstance().readTransactions();

      final now = DateTime.now();
      List<Transaction> openTransactions = [];
      for (final t in transactions) {
        if (t is! ErrorTransaction && t.timestamp.difference(now).inDays < 3) {
          dynamic res = await t.runOnline();
          if (res == null || (res is bool && !res)) {
            openTransactions.add(t);
          }
        }
      }
      TransactionStorage.getInstance().setTransaction(openTransactions);
    }
  }

  Future<T> runTransaction<T>(
    Transaction<T> t, {
    bool forceOffline = false,
    bool saveTransaction = true,
  }) async {
    forceOffline = forceOffline || App.isForcedOffline;
    if (!ApiService.getInstance().isConnected()) {
      await ApiService.getInstance().refresh();
    }
    if (!forceOffline && ApiService.getInstance().isConnected()) {
      try {
        T? res = await t.runOnline();
        if (res != null && (res is! bool || res)) return res;
      } on TransactionConflictException {
        // A conflicting transaction (e.g. duplicate item) must not be queued
        // for offline retry; surface the conflict to the caller instead.
        rethrow;
      }
    }
    if (t.saveTransaction && saveTransaction) {
      await TransactionStorage.getInstance().addTransaction(t);
    }

    return t.runLocal();
  }
}
