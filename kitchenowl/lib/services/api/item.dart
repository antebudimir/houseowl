import 'dart:convert';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_conflict_exception.dart';

extension ItemApi on ApiService {
  static const baseRoute = '/item';

  Future<List<Item>?> getAllItems(
    Household household,
  ) async {
    final res = await get('${householdPath(household)}$baseRoute');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Item.fromJson(e)).toList();
  }

  Future<Item?> getItem(Item item) async {
    final res = await get('$baseRoute/${item.id}');
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);

    return Item.fromJson(body);
  }

  Future<List<ItemWithDescription>?> searchItem(
    Household household,
    String query,
  ) async {
    final res = await get(
      '${householdPath(household)}$baseRoute/search',
      queryParameters: {
        "query": query,
      },
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ItemWithDescription.fromJson(e)).toList();
  }

  Future<bool> deleteItem(Item item) async {
    final res = await delete('$baseRoute/${item.id}');

    return res.statusCode == 200;
  }

  Future<bool> updateItem(Item item) async {
    final res =
        await post('$baseRoute/${item.id}', jsonEncode(item.toJsonWithId()));

    return res.statusCode == 200;
  }

  Future<bool> addItem(Household household, Item item) async {
    final res = await post('${householdPath(household)}$baseRoute',
        jsonEncode(item.toJsonWithId()));
    // A 400 means the payload was rejected; for this route that is a
    // duplicate item name (or invalid category) — a conflict, not a
    // network failure, so it must not be queued for offline retry.
    if (res.statusCode == 400) {
      throw const TransactionConflictException('item already exists');
    }

    return res.statusCode == 200;
  }

  Future<bool> mergeItems(Item item, Item other) async {
    final res = await post(
      '$baseRoute/${item.id}',
      jsonEncode({
        "merge_item_id": other.id,
      }),
    );

    return res.statusCode == 200;
  }
}
