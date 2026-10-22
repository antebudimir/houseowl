import 'dart:convert';

import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/planned_buy.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension PlannedBuyApi on ApiService {
  String plannedBuyRoute({Household? household, PlannedBuy? plannedBuy}) =>
      "${household != null ? householdPath(household) : ""}/planned_buy${plannedBuy?.id != null ? "/${plannedBuy!.id}" : ""}";

  Future<List<PlannedBuy>?> getPlannedBuys(Household household) async {
    final res = await get(plannedBuyRoute(household: household));
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body))
        .map((e) => PlannedBuy.fromJson(e))
        .toList();
  }

  Future<List<String>?> getPlannedBuyCategories(Household household) async {
    final res =
        await get("${plannedBuyRoute(household: household)}/categories");
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body)).map((e) => e as String).toList();
  }

  Future<PlannedBuy?> addPlannedBuy(
    Household household,
    PlannedBuy plannedBuy,
  ) async {
    final res = await post(
      plannedBuyRoute(household: household),
      jsonEncode(plannedBuy.toJson()),
    );
    if (res.statusCode != 200) return null;

    return PlannedBuy.fromJson(jsonDecode(res.body));
  }

  Future<bool> updatePlannedBuy(PlannedBuy plannedBuy) async {
    final res = await post(
      plannedBuyRoute(plannedBuy: plannedBuy),
      jsonEncode(plannedBuy.toJsonWithId()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deletePlannedBuy(PlannedBuy plannedBuy) async {
    final res = await delete(plannedBuyRoute(plannedBuy: plannedBuy));

    return res.statusCode == 200;
  }

  void onPlannedBuyUpdate(dynamic Function(dynamic) handler) {
    socket.on("planned_buy:update", handler);
  }

  void offPlannedBuyUpdate(dynamic Function(dynamic) handler) {
    socket.off("planned_buy:update", handler);
  }
}
