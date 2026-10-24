import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/item.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction.dart';

class TransactionItemGet extends Transaction<Item> {
  final Item item;

  TransactionItemGet({required this.item, DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionItemGet");

  @override
  Future<Item> runLocal() async {
    return item;
  }

  @override
  Future<Item?> runOnline() async {
    return await ApiService.getInstance().getItem(item);
  }
}

class TransactionItemUpdate extends Transaction<bool> {
  final Item item;

  TransactionItemUpdate({required this.item, DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionItemUpdate");

  @override
  Future<bool> runLocal() async {
    return false;
  }

  @override
  Future<bool?> runOnline() async {
    return await ApiService.getInstance().updateItem(item);
  }
}

class TransactionItemAdd extends Transaction<bool> {
  final Household household;
  final Item item;

  TransactionItemAdd({
    required this.household,
    required this.item,
    DateTime? timestamp,
  }) : super.internal(timestamp ?? DateTime.now(), "TransactionItemAdd");

  @override
  Future<bool> runLocal() async {
    return false;
  }

  @override
  Future<bool?> runOnline() async {
    return await ApiService.getInstance().addItem(household, item);
  }
}

