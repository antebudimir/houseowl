import 'dart:convert';

import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension LoyaltyCardApi on ApiService {
  String loyaltyCardRoute({Household? household, LoyaltyCard? card}) =>
      "${household != null ? householdPath(household) : ""}/loyalty_card${card?.id != null ? "/${card!.id}" : ""}";

  Future<List<LoyaltyCard>?> getLoyaltyCards(
    Household household, {
    String? search,
  }) async {
    final res = await get(
      loyaltyCardRoute(household: household),
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body))
        .map((e) => LoyaltyCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<String>?> getBarcodeFormats() async {
    final res = await get("/loyalty_card/formats");
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body)).cast<String>();
  }

  Future<LoyaltyCard?> addLoyaltyCard(
    Household household,
    LoyaltyCard card,
  ) async {
    final res = await post(
      loyaltyCardRoute(household: household),
      jsonEncode(card.toJson()),
    );
    if (res.statusCode != 200) return null;

    return LoyaltyCard.fromJson(jsonDecode(res.body));
  }

  Future<bool> updateLoyaltyCard(LoyaltyCard card) async {
    final res = await post(
      loyaltyCardRoute(card: card),
      jsonEncode(card.toJsonWithId()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteLoyaltyCard(LoyaltyCard card) async {
    final res = await delete(loyaltyCardRoute(card: card));

    return res.statusCode == 200;
  }

  void onLoyaltyCardUpdate(dynamic Function(dynamic) handler) {
    socket.on("loyalty_card:update", handler);
  }

  void offLoyaltyCardUpdate(dynamic Function(dynamic) handler) {
    socket.off("loyalty_card:update", handler);
  }
}
