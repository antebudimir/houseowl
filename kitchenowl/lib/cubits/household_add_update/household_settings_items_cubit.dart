import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/enums/shoppinglist_sorting.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/category.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/item.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction_handler.dart';
import 'package:houseowl/services/transactions/category.dart';

class HouseholdSettingsItemsCubit extends Cubit<HouseholdSettingsItemsState> {
  final Household household;

  HouseholdSettingsItemsCubit(this.household)
      : super(const LoadingHouseholdSettingsItemsState()) {
    refresh();
  }

  Future<void> refresh() async {
    final items = ApiService.getInstance().getAllItems(household);
    final categories = TransactionHandler.getInstance().runTransaction(
      TransactionCategoriesGet(household: household),
    );
    if (await items != null) {
      ShoppinglistSorting.sortShoppinglistItems(state.items, state.sorting);
      emit(HouseholdSettingsItemsState(
        items: (await items)!,
        categories: await categories,
        sorting: state.sorting,
      ));
    }
  }

  void incrementSorting() {
    setSorting(ShoppinglistSorting
        .values[(state.sorting.index + 1) % ShoppinglistSorting.values.length]);
  }

  void setSorting(ShoppinglistSorting sorting) {
    if (state is! LoadingHouseholdSettingsItemsState &&
        state.items != const []) {
      ShoppinglistSorting.sortShoppinglistItems(state.items, sorting);
    }
    emit(state.copyWith(sorting: sorting));
  }

  Future<void> deleteItem(Item item) async {
    if (item.id != null) {
      if (await ApiService.getInstance().deleteItem(item)) refresh();
    }
  }

  Future<void> mergeItem(Item item, Item other) async {
    if (item.id != null && other.id != null) {
      if (await ApiService.getInstance().mergeItems(item, other)) refresh();
    }
  }

  Future<void> setName(Item item, String name) async {
    if (item.id != null) {
      if (await ApiService.getInstance().updateItem(item.copyWith(name: name)))
        refresh();
    }
  }

  Future<void> setIcon(Item item, String? icon) async {
    if (item.id != null) {
      if (await ApiService.getInstance()
          .updateItem(item.copyWith(icon: Nullable(icon)))) refresh();
    }
  }
}

class HouseholdSettingsItemsState extends Equatable {
  final List<Item> items;
  final List<Category> categories;
  final ShoppinglistSorting sorting;

  const HouseholdSettingsItemsState({
    this.items = const [],
    this.categories = const [],
    this.sorting = ShoppinglistSorting.alphabetical,
  });

  HouseholdSettingsItemsState copyWith({
    ShoppinglistSorting? sorting,
  }) =>
      HouseholdSettingsItemsState(
        items: this.items,
        categories: this.categories,
        sorting: sorting ?? this.sorting,
      );

  @override
  List<Object?> get props => [items, categories, sorting];
}

class LoadingHouseholdSettingsItemsState extends HouseholdSettingsItemsState {
  const LoadingHouseholdSettingsItemsState({super.sorting});

  @override
  HouseholdSettingsItemsState copyWith({
    ShoppinglistSorting? sorting,
  }) =>
      LoadingHouseholdSettingsItemsState(
        sorting: sorting ?? this.sorting,
      );
}
