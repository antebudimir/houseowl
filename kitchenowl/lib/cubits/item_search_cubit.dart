import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/models/category.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/item.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:collection/collection.dart';

class ItemSearchCubit extends Cubit<ItemSearchState> {
  final Household household;

  /// Cache of the household's whole catalog, used to list a category's items
  /// without a search text while the category filter is active.
  List<Item>? _catalog;

  ItemSearchCubit(
    this.household,
    List<Item> selectedItems, {
    Category? categoryFilter,
  }) : super(
          ItemSearchState(
            selectedItems,
            '',
            const [],
            categoryFilter: categoryFilter,
          ),
        );

  void itemSelected(Item item) {
    final List<Item> selectedItems = List.from(state.selectedItems);
    if(!selectedItems.remove(item)) {
      selectedItems.add(item);
    }
    emit(ItemSearchState(
      selectedItems,
      '',
      state.searchResults,
      otherCategoryResults: state.otherCategoryResults,
      createItem: state.createItem,
      categoryFilter: state.categoryFilter,
    ));
  }

  /// The most relevant result for the current query: in-category match first,
  /// then a cross-category match, then the create-new row.
  Item? primaryResult() => state.searchResults.firstOrNull ??
      state.otherCategoryResults.firstOrNull ??
      state.createItem;

  /// Sets (or clears) the category filter and refreshes the visible results.
  Future<void> setCategoryFilter(Category? category) async {
    emit(ItemSearchState(
      state.selectedItems,
      state.query,
      state.searchResults,
      otherCategoryResults: state.otherCategoryResults,
      createItem: state.createItem,
      categoryFilter: category,
    ));
    if (state.query.isEmpty) {
      await loadCategoryItems();
    } else {
      await search(state.query);
    }
  }

  /// Without a search text, shows the active category's items straight from
  /// the catalog so the picker opens pre-filtered instead of empty.
  Future<void> loadCategoryItems() async {
    if (state.query.isNotEmpty) return;
    final filter = state.categoryFilter;
    if (filter == null) {
      emit(ItemSearchState(
        state.selectedItems,
        '',
        const [],
        categoryFilter: null,
      ));
      return;
    }
    _catalog ??=
        await ApiService.getInstance().getAllItems(household) ?? const [];
    final items = _catalog!
        .where((e) => e.category?.id == filter.id)
        .toList();
    emit(ItemSearchState(
      state.selectedItems,
      '',
      items,
      categoryFilter: filter,
    ));
  }

  Future<void> search(String query) async {
    if (query.isNotEmpty) {
      final (queryName, queryDescription) = parseQuery(query);
      final filter = state.categoryFilter;

      List<Item> items = [];
      for (Item item
          in (await ApiService.getInstance().searchItem(household, queryName) ??
              [])) {
        String? description = state.selectedItems
                .whereType<ItemWithDescription>()
                .firstWhereOrNull((e) => e.name == item.name)
                ?.description ??
            queryDescription;
        items.add(ItemWithDescription.fromItem(
          item: item,
          description: description,
        ));
      }

      // With a category filter active, matches from other categories stay
      // visible — moved into [otherCategoryResults] so the UI can render
      // them labeled and dimmed instead of hiding them.
      List<Item> otherCategoryItems = const [];
      if (filter != null) {
        otherCategoryItems =
            items.where((e) => e.category?.id != filter.id).toList();
        items = items.where((e) => e.category?.id == filter.id).toList();
      }

      // Offer creating the item when the category doesn't have an exact
      // match under this name yet — even if another category has one
      // (shown labeled above), creating a copy here is a conscious choice.
      ItemWithDescription? createItem;
      final hasExactMatch = items.isNotEmpty &&
          items[0].name.toLowerCase() == queryName.toLowerCase();
      if (!hasExactMatch) {
        createItem = ItemWithDescription(
          name: queryName,
          description: queryDescription ?? '',
        );
      }

      emit(ItemSearchState(
        state.selectedItems,
        query,
        items,
        otherCategoryResults: otherCategoryItems,
        createItem: createItem,
        categoryFilter: filter,
      ));
    } else {
      await loadCategoryItems();
    }
  }

  /// Scans the [query] for a comma and if found,
  /// returns a tuple consisting of the part before
  /// the comma and the remaining string.
  /// Otherwise returns the [query].
  (String, String?) parseQuery(String query) {
    final splitIndex = query.indexOf(",");
    if (splitIndex >= 0) {
      return (
        query.substring(0, splitIndex).trim(),
        query.substring(splitIndex + 1).trim()
      );
    }
    return (query, null);
  }
}

class ItemSearchState extends Equatable {
  final List<Item> selectedItems;
  final String query;

  /// Catalog matches inside the active category filter.
  final List<Item> searchResults;

  /// Catalog matches from other categories — rendered labeled and dimmed.
  final List<Item> otherCategoryResults;

  /// The "create new" entry for the query, when the category has no exact
  /// match for it yet.
  final ItemWithDescription? createItem;
  final Category? categoryFilter;

  const ItemSearchState(
    this.selectedItems,
    this.query,
    this.searchResults, {
    this.otherCategoryResults = const [],
    this.createItem,
    this.categoryFilter,
  });

  @override
  List<Object?> get props => [
        selectedItems,
        query,
        searchResults,
        otherCategoryResults,
        createItem,
        categoryFilter,
      ];
}
