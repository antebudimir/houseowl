import 'dart:convert';

import 'package:houseowl/enums/shoppinglist_sorting.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/item.dart';
import 'package:houseowl/models/shoppinglist.dart';
import 'package:houseowl/services/api/api_service.dart';

extension ShoppinglistApi on ApiService {
  static const baseRoute = '/shoppinglist';
  String route({Household? household, ShoppingList? shoppinglist}) =>
      "${household != null ? householdPath(household) : ""}$baseRoute${shoppinglist?.id != null ? "/${shoppinglist!.id}" : ""}";

  Future<List<ShoppingList>?> getShoppingLists(
    Household household, {
    ShoppinglistSorting sorting = ShoppinglistSorting.alphabetical,
    int recentItemlimit = 9,
  }) async {
    recentItemlimit = recentItemlimit > 120 ? 120 : recentItemlimit;
    final res = await get(
      route(household: household),
      queryParameters: {
        'orderby': sorting.index.toString(),
        'recent_limit': recentItemlimit.toString(),
      },
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ShoppingList.fromJson(e)).toList();
  }

  Future<List<Item>> getSuggestedItems(ShoppingList shoppinglist) async {
    final res =
        await get('${route(shoppinglist: shoppinglist)}/suggested-items');
    if (res.statusCode != 200) return const [];

    final body = List.from(jsonDecode(res.body));

    return body
        .map((e) => Item.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<bool> addShoppingList(
    Household household,
    ShoppingList shoppingList,
  ) async {
    final res = await post(
      route(household: household),
      jsonEncode(shoppingList.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateShoppingList(
    ShoppingList shoppingList,
  ) async {
    final res = await post(
      route(shoppinglist: shoppingList),
      jsonEncode(shoppingList.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteShoppingList(
    ShoppingList shoppingList,
  ) async {
    final res = await delete(route(shoppinglist: shoppingList));

    return res.statusCode == 200;
  }

  Future<bool> putItem(
    ShoppingList shoppinglist,
    Item item,
  ) async {
    // The backend requires a description on this route; send an empty
    // string for plain items without one.
    final String description =
        item is ItemWithDescription ? item.description : '';
    final res = await put(
      '${route(shoppinglist: shoppinglist)}/item/${item.id}',
      jsonEncode({'description': description}),
    );

    return res.statusCode == 200;
  }

  Future<bool> addItemByName(
    ShoppingList shoppinglist,
    String name, [
    String? description,
  ]) async {
    final data = {'name': name};
    if (description != null) data['description'] = description;
    final res = await post(
      '${route(shoppinglist: shoppinglist)}/add-item-by-name',
      jsonEncode(data),
    );

    return res.statusCode == 200;
  }

  Future<bool> removeItem(
    ShoppingList shoppinglist,
    ShoppinglistItem item, [
    DateTime? time,
  ]) async {
    final res = await delete(
      '${route(shoppinglist: shoppinglist)}/item',
      body: jsonEncode({
        'item_id': item.id,
        if (time != null) 'removed_at': time.toUtc().millisecondsSinceEpoch,
      }),
    );

    return res.statusCode == 200;
  }

  Future<bool> removeItems(
    ShoppingList shoppinglist,
    List<ShoppinglistItem> items, [
    DateTime? time,
  ]) async {
    final res = await delete(
      '${route(shoppinglist: shoppinglist)}/items',
      body: jsonEncode({
        "items": items
            .map(
              (item) => {
                'item_id': item.id,
                if (time != null)
                  'removed_at': time.toUtc().millisecondsSinceEpoch,
              },
            )
            .toList(),
      }),
    );

    return res.statusCode == 200;
  }

  void onShoppinglistAdd(dynamic Function(dynamic) handler) {
    socket.on("shoppinglist:add", handler);
  }

  void offShoppinglistAdd(dynamic Function(dynamic) handler) {
    socket.off("shoppinglist:add", handler);
  }

  void onShoppinglistDelete(dynamic Function(dynamic) handler) {
    socket.on("shoppinglist:delete", handler);
  }

  void offShoppinglistDelete(dynamic Function(dynamic) handler) {
    socket.off("shoppinglist:delete", handler);
  }

  void onShoppinglistUpdate(dynamic Function(dynamic) handler) {
    socket.on("shoppinglist:update", handler);
  }

  void offShoppinglistUpdate(dynamic Function(dynamic) handler) {
    socket.off("shoppinglist:update", handler);
  }

  void onShoppinglistItemAdd(dynamic Function(dynamic) handler) {
    socket.on("shoppinglist_item:add", handler);
  }

  void offShoppinglistItemAdd(dynamic Function(dynamic) handler) {
    socket.off("shoppinglist_item:add", handler);
  }

  void onShoppinglistItemRemove(dynamic Function(dynamic) handler) {
    socket.on("shoppinglist_item:remove", handler);
  }

  void offShoppinglistItemRemove(dynamic Function(dynamic) handler) {
    socket.off("shoppinglist_item:remove", handler);
  }
}
