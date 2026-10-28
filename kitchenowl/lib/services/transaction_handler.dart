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
      int expired = 0;
      for (final t in transactions) {
        if (t is ErrorTransaction) continue;
        if (t.timestamp.difference(now).inDays >= 3) {
          // Queued too long: replaying a stale change is worse than losing
          // it, but the drop must not be silent.
          expired++;
          continue;
        }
        try {
          dynamic res = await t.runOnline();
          if (res == null || (res is bool && !res)) {
            openTransactions.add(t);
          }
        } on TransactionConflictException {
          // Permanent conflict (e.g. the item was created concurrently on
          // another device): retrying can never succeed — drop it.
        } catch (e) {
          // One failing transaction must not block the rest of the queue:
          // keep it and continue with the next.
          openTransactions.add(t);
        }
      }
      TransactionStorage.getInstance().setTransaction(openTransactions);

      if (expired > 0) App.notifyOfflineQueueExpired(expired);
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
