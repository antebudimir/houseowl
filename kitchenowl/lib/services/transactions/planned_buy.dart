import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/planned_buy.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction.dart';

/// Planned buys are online-only: there is no offline cache, mirroring the
/// former expense transactions.
class TransactionPlannedBuysGet extends Transaction<List<PlannedBuy>> {
  final Household household;

  TransactionPlannedBuysGet({
    required this.household,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannedBuysGet",
        );

  @override
  Future<List<PlannedBuy>> runLocal() async => [];

  @override
  Future<List<PlannedBuy>> runOnline() async =>
      await ApiService.getInstance().getPlannedBuys(household) ?? [];
}

class TransactionPlannedBuyAdd extends Transaction<bool> {
  final Household household;
  final PlannedBuy plannedBuy;

  TransactionPlannedBuyAdd({
    required this.household,
    required this.plannedBuy,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannedBuyAdd",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() async =>
      await ApiService.getInstance().addPlannedBuy(household, plannedBuy) !=
      null;
}

class TransactionPlannedBuyUpdate extends Transaction<bool> {
  final PlannedBuy plannedBuy;

  TransactionPlannedBuyUpdate({
    required this.plannedBuy,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannedBuyUpdate",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() =>
      ApiService.getInstance().updatePlannedBuy(plannedBuy);
}

class TransactionPlannedBuyRemove extends Transaction<bool> {
  final PlannedBuy plannedBuy;

  TransactionPlannedBuyRemove({
    required this.plannedBuy,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannedBuyRemove",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() =>
      ApiService.getInstance().deletePlannedBuy(plannedBuy);
}
