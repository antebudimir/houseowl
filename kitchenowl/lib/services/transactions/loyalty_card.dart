import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/loyalty_card.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction.dart';

/// Loyalty cards are online-only: there is no offline cache, mirroring
/// document transactions.
class TransactionLoyaltyCardsGet extends Transaction<List<LoyaltyCard>> {
  final Household household;
  final String? query;

  TransactionLoyaltyCardsGet({
    required this.household,
    this.query,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionLoyaltyCardsGet",
        );

  @override
  Future<List<LoyaltyCard>> runLocal() async => [];

  @override
  Future<List<LoyaltyCard>> runOnline() async =>
      await ApiService.getInstance().getLoyaltyCards(
        household,
        search: query,
      ) ??
      [];
}

class TransactionLoyaltyCardAdd extends Transaction<bool> {
  final Household household;
  final LoyaltyCard card;

  TransactionLoyaltyCardAdd({
    required this.household,
    required this.card,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionLoyaltyCardAdd",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() async =>
      await ApiService.getInstance().addLoyaltyCard(household, card) != null;
}

class TransactionLoyaltyCardUpdate extends Transaction<bool> {
  final LoyaltyCard card;

  TransactionLoyaltyCardUpdate({
    required this.card,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionLoyaltyCardUpdate",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() => ApiService.getInstance().updateLoyaltyCard(card);
}

class TransactionLoyaltyCardRemove extends Transaction<bool> {
  final LoyaltyCard card;

  TransactionLoyaltyCardRemove({
    required this.card,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionLoyaltyCardRemove",
        );

  @override
  Future<bool> runLocal() async => false;

  @override
  Future<bool?> runOnline() => ApiService.getInstance().deleteLoyaltyCard(card);
}
