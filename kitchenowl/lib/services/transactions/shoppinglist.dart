import 'package:houseowl/app.dart';
import 'package:houseowl/enums/shoppinglist_sorting.dart';
import 'package:houseowl/helpers/item_name.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/item.dart';
import 'package:houseowl/models/shoppinglist.dart';
import 'package:houseowl/services/storage/mem_storage.dart';
import 'package:houseowl/services/transaction.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction_conflict_exception.dart';

class TransactionShoppingListGet extends Transaction<List<ShoppingList>> {
  final Household household;
  final ShoppinglistSorting sorting;

  TransactionShoppingListGet({
    DateTime? timestamp,
    required this.household,
    this.sorting = ShoppinglistSorting.alphabetical,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListGet",
        );

  @override
  Future<List<ShoppingList>> runLocal() async {
    return await MemStorage.getInstance().readShoppingLists(household) ?? [];
  }

  @override
  Future<List<ShoppingList>?> runOnline() async {
    final lists = await ApiService.getInstance().getShoppingLists(
      household,
      sorting: sorting,
      recentItemlimit: App.settings.recentItemsCount + 3,
    );
    if (lists != null) {
      MemStorage.getInstance().writeShoppingLists(household, lists);
    }

    return lists;
  }
}

class TransactionShoppingListSearchItem extends Transaction<List<Item>> {
  final Household household;
  final String query;

  TransactionShoppingListSearchItem({
    required this.household,
    required this.query,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListSearchItem",
        );

  @override
  Future<List<Item>> runLocal() async {
    final normalizedQuery = normalizeItemName(query);
    final shoppingLists =
        await MemStorage.getInstance().readShoppingLists(household);
    return (shoppingLists
            ?.map((shoppingList) =>
                shoppingList.recentItems
                    .map((e) => Item.fromItem(item: e))
                    .toList() +
                shoppingList.items)
            .fold<List<Item>>(
          [],
          (p, e) => p + e,
        ) ??
        [])
      ..retainWhere((e) => normalizeItemName(e.name).contains(normalizedQuery));
  }

  @override
  Future<List<Item>?> runOnline() async {
    return await ApiService.getInstance().searchItem(household, query);
  }
}

class TransactionShoppingListAddItem extends Transaction<bool> {
  final Household household;
  final ShoppingList shoppinglist;
  final Item item;

  TransactionShoppingListAddItem({
    required this.household,
    required this.shoppinglist,
    required this.item,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListAddItem",
        );

  factory TransactionShoppingListAddItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionShoppingListAddItem(
        household: Household.fromJson(map['household']),
        shoppinglist: ShoppingList.fromJson(map['shoppinglist']),
        item: ItemWithDescription.fromJson(map['item']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "shoppinglist": shoppinglist.toJsonWithId(),
      "item": item.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final shoppingLists =
        await MemStorage.getInstance().readShoppingLists(household) ?? [];
    final latestShoppingList =
        shoppingLists.where((e) => e.id == shoppinglist.id).firstOrNull;
    if (latestShoppingList == null) return false;
    latestShoppingList.items.add(ShoppinglistItem.fromItem(item: item));
    latestShoppingList.recentItems
        .removeWhere((item) => item.name == this.item.name);
    MemStorage.getInstance().writeShoppingLists(household, shoppingLists);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    if (item.id != null) {
      return ApiService.getInstance().putItem(
        shoppinglist,
        item,
      );
    }
    // A created item carrying a category must create the catalog item with
    // that category first — the add-item-by-name route only takes a name
    // and would file it as uncategorized. The by-name call afterwards links
    // the now-existing categorized item to the list, so the catalog entry is
    // reusable in that category next time.
    if (item.category?.id != null) {
      return _createCategorizedItemThenLink();
    }
    return ApiService.getInstance().addItemByName(
      shoppinglist,
      item.name,
      _itemDescription(),
    );
  }

  String _itemDescription() =>
      item is ItemWithDescription ? (item as ItemWithDescription).description : "";

  Future<bool> _createCategorizedItemThenLink() async {
    final api = ApiService.getInstance();
    try {
      final created = await api.addItem(household, item);
      if (!created) return false;
    } on TransactionConflictException {
      // The item was created concurrently (e.g. by another device); linking
      // it by name still succeeds — its category is whatever won the race.
    }
    return api.addItemByName(
      shoppinglist,
      item.name,
      _itemDescription(),
    );
  }
}

class TransactionShoppingListRemoveItem extends Transaction<bool> {
  final Household household;
  final ShoppingList shoppinglist;
  final ShoppinglistItem item;

  TransactionShoppingListRemoveItem({
    DateTime? timestamp,
    required this.household,
    required this.item,
    required this.shoppinglist,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListDeleteItem",
        );

  factory TransactionShoppingListRemoveItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionShoppingListRemoveItem(
        household: Household.fromJson(map['household']),
        shoppinglist: ShoppingList.fromJson(map['shoppinglist']),
        item: ShoppinglistItem.fromJson(map['item']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'household': household.toJsonWithId(),
      "shoppinglist": shoppinglist.toJsonWithId(),
      "item": item.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final shoppingLists =
        await MemStorage.getInstance().readShoppingLists(household) ?? [];
    final latestShoppingList =
        shoppingLists.where((e) => e.id == shoppinglist.id).firstOrNull;
    if (latestShoppingList == null) return false;
    latestShoppingList.items.removeWhere((e) => e.name == item.name);
    latestShoppingList.recentItems.removeWhere((e) => e.name == item.name);
    latestShoppingList.recentItems.insert(0, item);
    MemStorage.getInstance().writeShoppingLists(household, shoppingLists);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    runLocal();

    return ApiService.getInstance().removeItem(shoppinglist, item, timestamp);
  }
}

class TransactionShoppingListRemoveItems extends Transaction<bool> {
  final Household household;
  final ShoppingList shoppinglist;
  final List<ShoppinglistItem> items;

  TransactionShoppingListRemoveItems({
    DateTime? timestamp,
    required this.household,
    required this.items,
    required this.shoppinglist,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListDeleteItems",
        );

  factory TransactionShoppingListRemoveItems.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionShoppingListRemoveItems(
        household: Household.fromJson(map['household']),
        shoppinglist: ShoppingList.fromJson(map['shoppinglist']),
        items: List.from(map['items'])
            .map((e) => ShoppinglistItem.fromJson(e))
            .toList(),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'household': household.toJsonWithId(),
      "shoppinglist": shoppinglist.toJsonWithId(),
      "items": items.map((e) => e.toJsonWithId()).toList(),
    });

  @override
  Future<bool> runLocal() async {
    final shoppingLists =
        await MemStorage.getInstance().readShoppingLists(household) ?? [];
    final latestShoppingList =
        shoppingLists.where((e) => e.id == shoppinglist.id).firstOrNull;
    if (latestShoppingList == null) return false;
    latestShoppingList.items
        .removeWhere((e) => items.map((e) => e.name).contains(e.name));
    latestShoppingList.recentItems.insertAll(0, items);
    MemStorage.getInstance().writeShoppingLists(household, shoppingLists);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    runLocal();

    return ApiService.getInstance().removeItems(shoppinglist, items, timestamp);
  }
}

class TransactionShoppingListUpdateItem extends Transaction<bool> {
  final Household household;
  final ShoppingList shoppinglist;
  final Item item;
  final String description;

  TransactionShoppingListUpdateItem({
    required this.household,
    required this.shoppinglist,
    required this.item,
    required this.description,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListUpdateItem",
        );

  factory TransactionShoppingListUpdateItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionShoppingListUpdateItem(
        household: Household.fromJson(map['household']),
        shoppinglist: ShoppingList.fromJson(map['shoppinglist']),
        item: Item.fromJson(map['item']),
        description: map['description'],
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'household': household.toJsonWithId(),
      "shoppinglist": shoppinglist.toJsonWithId(),
      "item": item.toJsonWithId(),
      "description": description,
    });

  @override
  Future<bool> runLocal() async {
    final shoppingLists =
        await MemStorage.getInstance().readShoppingLists(household) ?? [];
    final latestShoppingList =
        shoppingLists.where((e) => e.id == shoppinglist.id).firstOrNull;
    if (latestShoppingList == null) return false;

    if (item is ShoppinglistItem) {
      final int i = latestShoppingList.items.indexWhere((e) => e.id == item.id);
      latestShoppingList.items[i] =
          (item as ShoppinglistItem).copyWith(description: description);
      MemStorage.getInstance().writeShoppingLists(household, shoppingLists);

      return true;
    } else if (description.isNotEmpty) {
      latestShoppingList.items
          .add(ShoppinglistItem(name: item.name, description: description));
      latestShoppingList.recentItems
          .removeWhere((item) => item.name == this.item.name);
      MemStorage.getInstance().writeShoppingLists(household, shoppingLists);

      return true;
    }

    return false;
  }

  @override
  Future<bool?> runOnline() async {
    return ApiService.getInstance().putItem(
      shoppinglist,
      ItemWithDescription.fromItem(item: item, description: description),
    );
  }
}

