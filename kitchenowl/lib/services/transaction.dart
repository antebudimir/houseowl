import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/services/transactions/note.dart';
import 'package:kitchenowl/services/transactions/person.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

abstract class Transaction<T> extends Model {
  static final Map<String, Transaction Function(Map<String, dynamic>, DateTime)>
      _transactionTypes = {
    "TransactionShoppingListAddItem": (m, t) =>
        TransactionShoppingListAddItem.fromJson(m, t),
    "TransactionShoppingListDeleteItem": (m, t) =>
        TransactionShoppingListRemoveItem.fromJson(m, t),
    "TransactionShoppingListDeleteItems": (m, t) =>
        TransactionShoppingListRemoveItems.fromJson(m, t),
    "TransactionShoppingListUpdateItem": (m, t) =>
        TransactionShoppingListUpdateItem.fromJson(m, t),
    "TransactionPersonAdd": (m, t) => TransactionPersonAdd.fromJson(m, t),
    "TransactionPersonUpdate": (m, t) =>
        TransactionPersonUpdate.fromJson(m, t),
    "TransactionPersonRemove": (m, t) =>
        TransactionPersonRemove.fromJson(m, t),
    "TransactionNotesGet": (m, t) =>
        TransactionNotesGet.fromJson(m, t),
    "TransactionNoteAdd": (m, t) => TransactionNoteAdd.fromJson(m, t),
    "TransactionNoteUpdate": (m, t) =>
        TransactionNoteUpdate.fromJson(m, t),
    "TransactionNoteRemove": (m, t) =>
        TransactionNoteRemove.fromJson(m, t),
  };

  bool get saveTransaction => false;

  final String className;
  final DateTime timestamp;

  Future<T> runLocal();
  Future<T?> runOnline();

  const Transaction.internal(this.timestamp, this.className);

  factory Transaction.fromJson(Map<String, dynamic> map) {
    final DateTime timestamp =
        DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    if (map.containsKey('className') &&
        _transactionTypes.containsKey(map['className'])) {
      try {
        return _transactionTypes[map['className']]!(map, timestamp)
            as Transaction<T>;
      } catch (e) {
        return ErrorTransaction<T>(
            timestamp,
            map.containsKey('className') ? map['className'] : "ERROR",
            e.toString());
      }
    }

    return ErrorTransaction<T>(
        timestamp,
        map.containsKey('className') ? map['className'] : "ERROR",
        "Could not find transaction class");
  }

  @override
  List<Object> get props => [className, timestamp];

  @override
  Map<String, dynamic> toJson() => {
        "className": className,
        "timestamp": timestamp.toIso8601String(),
      };
}

class ErrorTransaction<T> extends Transaction<T> {
  final String message;

  const ErrorTransaction(super.timestamp, super.className, [this.message = ""])
      : super.internal();

  @override
  Future<T> runLocal() {
    throw UnimplementedError();
  }

  @override
  Future<T> runOnline() {
    throw UnimplementedError();
  }
}
