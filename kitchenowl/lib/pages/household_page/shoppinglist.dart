import 'package:animations/animations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/app.dart';
import 'package:houseowl/cubits/settings_cubit.dart';
import 'package:houseowl/cubits/shoppinglist_cubit.dart';
import 'package:houseowl/enums/shoppinglist_sorting.dart';
import 'package:houseowl/models/category.dart';
import 'package:houseowl/models/item.dart';
import 'package:houseowl/pages/item_search_page.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/widgets/shopping_list/shoppinglist_header.dart';
import 'package:houseowl/widgets/shopping_list/sliver_shopinglist_item_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ShoppinglistPage extends StatefulWidget {
  const ShoppinglistPage({super.key});

  @override
  _ShoppinglistPageState createState() => _ShoppinglistPageState();
}

class _ShoppinglistPageState extends State<ShoppinglistPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.text = BlocProvider.of<ShoppinglistCubit>(context).query;
    if (BlocProvider.of<SettingsCubit>(context).state.shoppingListKeepAwake) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    searchController.dispose();
    super.dispose();
  }

  Future<void> addItemsFromCategory(
      BuildContext context, Category category) async {
    final cubit = BlocProvider.of<ShoppinglistCubit>(context);
    final items = await Navigator.of(context, rootNavigator: true)
            .push<List<Item>>(MaterialPageRoute(
          builder: (context) => ItemSearchPage(
            household: cubit.household,
            title: category.name,
            category: category,
            onAdd: (item) async {
              // Created items are added to the list immediately (tagged
              // with the category); the search page keeps them ticked and
              // excludes them from the bulk selection returned on pop.
              await cubit.add(item.copyWith(category: Nullable(category)));
            },
          ),
        )) ??
        [];
    for (final item in items) {
      await cubit.add(
        item.id == null ? item.copyWith(category: Nullable(category)) : item,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<ShoppinglistCubit>(context);

    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: BlocListener<ShoppinglistCubit, ShoppinglistCubitState>(
                bloc: cubit,
                listener: (context, state) {
                  if (state is! SearchShoppinglistCubitState &&
                      state is! LoadingShoppinglistCubitState) {
                    if (searchController.text.isNotEmpty) {
                      searchController.clear();
                    }
                  }
                },
                child: SearchTextField(
                  controller: searchController,
                  onSearch: (s) => cubit.search(s),
                  onSubmitted: () {
                    final state = cubit.state;
                    if (state is SearchShoppinglistCubitState) {
                      if (state.result.first is! ShoppinglistItem) {
                        cubit.add(state.result.first);
                      }
                    } else {
                      cubit.search(searchController.text);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ShoppinglistCubit, ShoppinglistCubitState>(
              bloc: cubit,
              builder: (context, state) {
                final header = LeftRightWrap(
                  left: ShoppinglistHeader(
                    shoppinglists: state.shoppinglists.values.toList(),
                    selectedShoppinglistId: state.selectedShoppinglistId,
                    onSelect: cubit.setShoppingList,
                    onAdd: cubit.addShoppingList,
                    onDelete: cubit.deleteShoppingList,
                    onRename: cubit.updateShoppingList,
                  ),
                  right: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 6),
                    child: TrailingIconTextButton(
                      onPressed: cubit.incrementSorting,
                      text: state.sorting == ShoppinglistSorting.alphabetical
                          ? AppLocalizations.of(context)!.sortingAlphabetical
                          : state.sorting == ShoppinglistSorting.algorithmic
                              ? AppLocalizations.of(context)!.sortingAlgorithmic
                              : AppLocalizations.of(context)!.category,
                      icon: const Icon(Icons.sort),
                    ),
                  ),
                );

                if (state is! SearchShoppinglistCubitState &&
                    state is! LoadingShoppinglistCubitState &&
                    (state.selectedShoppinglist?.items.isEmpty ?? true) &&
                    ((state.selectedShoppinglist?.recentItems.isEmpty ??
                            true) ||
                        (App.settings.recentItemsCount == 0))) {
                  return Column(
                    children: [
                      header,
                      const Spacer(),
                      const Icon(Icons.remove_shopping_cart_rounded),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.shoppingListEmpty,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                    ],
                  );
                }
                return BlocBuilder<SettingsCubit, SettingsState>(
                  buildWhen: (previous, current) =>
                      previous.shoppingListListView !=
                          current.shoppingListListView ||
                      previous.listStyle != current.listStyle ||
                      previous.gridSize != current.gridSize,
                  builder: (context, settingsState) => PageTransitionSwitcher(
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                    ) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.vertical,
                        fillColor: Colors.transparent,
                        child: child,
                      );
                    },
                    child: (state is SearchShoppinglistCubitState)
                        ? RefreshIndicator(
                            onRefresh: cubit.refresh,
                            child: CustomScrollView(
                              primary: true,
                              slivers: [
                                SliverItemGridList(
                                  shoppingListStyle: ShoppingListStyle(
                                    listStyle: settingsState.listStyle,
                                    isList: settingsState.shoppingListListView,
                                    gridSize: settingsState.gridSize,
                                  ),
                                  items: state.result,
                                  categories: state.categories,
                                  shoppingList: state.selectedShoppinglist,
                                  onRefresh: () => cubit.refresh(),
                                  selected: (item) =>
                                      item is ShoppinglistItem &&
                                      (App.settings.shoppingListTapToRemove ||
                                          !state.selectedListItems
                                              .contains(item)),
                                  isLoading:
                                      state is LoadingShoppinglistCubitState,
                                  onPressed: Nullable((Item item) {
                                    if (item is ShoppinglistItem) {
                                      if (App
                                          .settings.shoppingListTapToRemove) {
                                        cubit.remove(item);
                                      } else {
                                        cubit.selectItem(item);
                                      }
                                    } else {
                                      cubit.add(item);
                                    }
                                  }),
                                ),
                              ],
                            ),
                          )
                        : NestedScrollView(
                            headerSliverBuilder:
                                (context, innerBoxIsScrolled) => [
                              SliverToBoxAdapter(child: header),
                            ],
                            body: RefreshIndicator(
                              onRefresh: cubit.refresh,
                              displacement: 0,
                              child: PageTransitionSwitcher(
                                transitionBuilder: (
                                  Widget child,
                                  Animation<double> animation,
                                  Animation<double> secondaryAnimation,
                                ) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.vertical,
                                    fillColor: Colors.transparent,
                                    child: child,
                                  );
                                },
                                child: CustomScrollView(
                                  key: PageStorageKey<int?>(
                                      state.selectedShoppinglistId),
                                  slivers: [
                                    SliverShopinglistItemView(
                                      shoppingListStyle: ShoppingListStyle(
                                        listStyle: settingsState.listStyle,
                                        isList:
                                            settingsState.shoppingListListView,
                                        gridSize: settingsState.gridSize,
                                      ),
                                      categories: state.categories,
                                      isLoading: state
                                          is LoadingShoppinglistCubitState,
                                      selectedListItems:
                                          state.selectedListItems,
                                      sorting: state.sorting,
                                      shoppingList: state.selectedShoppinglist,
                                      onPressed: Nullable((Item item) {
                                        if (item is ShoppinglistItem) {
                                          if (App.settings
                                              .shoppingListTapToRemove) {
                                            cubit.remove(item);
                                          } else {
                                            cubit.selectItem(item);
                                          }
                                        } else {
                                          cubit.add(item);
                                        }
                                      }),
                                      onRecentPressed: Nullable(cubit.add),
                                      onRefresh: cubit.refresh,
                                      onAddCategory: Nullable(
                                          (Category category) =>
                                              addItemsFromCategory(
                                                  context, category)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
