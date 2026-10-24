import 'package:houseowl/services/transaction.dart';
import 'package:houseowl/services/transaction_handler.dart';

class LocalOnlyTransactionHandler extends TransactionHandler {
  LocalOnlyTransactionHandler() : super.internal();

  @override
  Future<T> runTransaction<T>(Transaction<T> t,
      {bool forceOffline = false, bool saveTransaction = true}) {
    return t.runLocal();
  }
}