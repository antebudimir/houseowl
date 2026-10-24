import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/category.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/item.dart';
import 'package:houseowl/models/shoppinglist.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/item.dart';
import 'package:houseowl/services/transactions/shoppinglist.dart';

class ItemEditCubit<T extends Item> extends Cubit<ItemEditState> {
  final Household? household;
  final T _item;
  final ShoppingList? shoppingList;

  T get item {
    if (_item is ItemWithDescription) {
      return (((_item as ItemWithDescription).copyWith(
        description: state.description,
        category: Nullable(state.category),
        icon: Nullable(state.icon),
        name: state.name,
      )) as T);
    }

    return _item.copyWith(
      category: Nullable(state.category),
      icon: Nullable(state.icon),
      name: state.name,
    ) as T;
  }

  ItemEditCubit({required T item, required this.household, this.shoppingList})
      : _item = item,
        super(ItemEditState(
          description: (item is ItemWithDescription) ? item.description : '',
          icon: item.icon,
          name: item.name,
          category: item.category,
        )) {
    refresh();
  }

  Future<void> refresh() async {}

  Future<void> saveItem() async {
    if (shoppingList != null && state.hasChangedDescription(_item)) {
      await TransactionHandler.getInstance()
          .runTransaction(TransactionShoppingListUpdateItem(
        household: household!,
        shoppinglist: shoppingList!,
        item: _item,
        description: state.description,
      ));
    }
    if (state.hasChangedItem(_item)) {
      if (item.id != null) {
        await TransactionHandler.getInstance()
            .runTransaction(TransactionItemUpdate(
          item: item,
        ));
      } else if (household != null) {
        await TransactionHandler.getInstance()
            .runTransaction(TransactionItemAdd(
          household: household!,
          item: item,
        ));
      }
    }
  }

  /// Adds the item to [targetList] and removes it from the item's current
  /// shopping list. The add runs before the remove so the item is never lost
  /// if the flow is interrupted. Offline-safe: both transactions queue in
  /// TransactionStorage and apply locally via runLocal.
  Future<bool> moveItem(ShoppingList targetList) async {
    final sourceList = shoppingList;
    if (sourceList == null ||
        targetList.id == null ||
        targetList.id == sourceList.id) {
      return false;
    }
    final handler = TransactionHandler.getInstance();
    final added = await handler.runTransaction(TransactionShoppingListAddItem(
      household: household!,
      shoppinglist: targetList,
      item: _item,
    ));
    if (!added) return false;

    return handler.runTransaction(TransactionShoppingListRemoveItem(
      household: household!,
      shoppinglist: sourceList,
      item: ShoppinglistItem.fromItem(item: _item),
    ));
  }

  Future<bool> deleteItem() async {
    if (_item.id != null) {
      return ApiService.getInstance().deleteItem(_item);
    }

    return false;
  }

  Future<bool> mergeItem(Item other) async {
    if (_item.id != null &&
        other.id != null &&
        await ApiService.getInstance().mergeItems(_item, other)) {
      emit(state.copyWith(hasMerged: true));
      return true;
    }

    return false;
  }

  void setName(String name) {
    emit(state.copyWith(name: name));
  }

  void setDescription(String desc) {
    emit(state.copyWith(description: desc));
  }

  void setCategory(Category? category) {
    emit(state.copyWith(
      category: Nullable(category),
    ));
  }

  void setIcon(String? icon) {
    emit(state.copyWith(
      icon: Nullable(icon),
    ));
  }
}

class ItemEditState extends Equatable {
  final String name;
  final String description;
  final String? icon;
  final Category? category;
  final bool hasMerged;

  const ItemEditState({
    this.name = "",
    this.description = "",
    this.icon,
    this.category,
    this.hasMerged = false,
  });

  ItemEditState copyWith({
    String? name,
    String? description,
    Nullable<String>? icon,
    Nullable<Category>? category,
    bool? hasMerged,
  }) =>
      ItemEditState(
        name: name ?? this.name,
        description: description ?? this.description,
        icon: (icon ?? Nullable(this.icon)).value,
        category: (category ?? Nullable(this.category)).value,
        hasMerged: hasMerged ?? this.hasMerged,
      );

  @override
  List<Object?> get props =>
      [name, description, icon, category, hasMerged];

  bool hasChanged(Item comparedTo) =>
      hasChangedItem(comparedTo) || hasChangedDescription(comparedTo);

  bool hasChangedItem(Item comparedTo) =>
      comparedTo.category != category ||
      comparedTo.icon != icon ||
      comparedTo.name != name ||
      hasMerged;

  bool hasChangedDescription(Item comparedTo) {
    return comparedTo is ItemWithDescription &&
        (comparedTo).description != description;
  }
}
