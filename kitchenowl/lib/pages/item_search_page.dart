import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/item_search_cubit.dart';
import 'package:houseowl/models/category.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/item.dart';
import 'package:houseowl/kitchenowl.dart';

class ItemSearchPage extends StatefulWidget {
  final Household household;
  final bool multiple;
  final List<Item> selectedItems;
  final String? title;

  /// When set, results are pre-filtered to this category with a chip to
  /// clear the filter; cross-category matches stay visible, labeled.
  final Category? category;

  /// When set, tapping the create row hands the created item to this
  /// callback (which adds it to the shopping list) instead of merely
  /// selecting it — the row then disappears and the item shows up
  /// in-category, already added.
  final Future<void> Function(Item item)? onAdd;

  const ItemSearchPage({
    super.key,
    required this.household,
    this.multiple = true,
    this.title,
    this.selectedItems = const [],
    this.category,
    this.onAdd,
  });

  @override
  _ItemSearchPageState createState() => _ItemSearchPageState();
}

class _ItemSearchPageState extends State<ItemSearchPage> {
  final TextEditingController searchController = TextEditingController();
  late ItemSearchCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = ItemSearchCubit(
      widget.household,
      widget.selectedItems,
      categoryFilter: widget.category,
    );
    if (widget.category != null) cubit.loadCategoryItems();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  Future<void> _handleCreate(ItemWithDescription created) async {
    if (widget.onAdd == null) {
      if (!widget.multiple) {
        Navigator.of(context).pop([created]);
      } else {
        cubit.itemSelected(created);
      }
      return;
    }
    await widget.onAdd!(created);
    if (!mounted) return;
    cubit.markCreatedAdded(created);
  }

  @override
  Widget build(BuildContext context) {
    final appbar = AppBar(
      title: Text(widget.title ?? AppLocalizations.of(context)!.itemsAdd),
      leading: BackButton(
        onPressed: () => Navigator.of(context).pop(cubit.state.selectedItems),
      ),
      flexibleSpace: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: BlocListener<ItemSearchCubit, ItemSearchState>(
              bloc: cubit,
              listener: (context, state) {
                if (state.query.isEmpty && searchController.text.isNotEmpty) {
                  searchController.clear();
                }
              },
              child: SearchTextField(
                controller: searchController,
                onSearch: cubit.search,
                autofocus: true,
                alwaysExpanded: true,
                textInputAction: TextInputAction.done,
                onSubmitted: () {
                  if (cubit.state.query != searchController.text) {
                    cubit.search(searchController.text);
                    return;
                  }
                  final item = cubit.primaryResult();
                  if (item == null) return;
                  if (widget.onAdd != null && item == cubit.state.createItem) {
                    _handleCreate(cubit.state.createItem!);
                    return;
                  }
                  if (cubit.state.selectedItems.contains(item)) return;
                  if (!widget.multiple) {
                    Navigator.of(context).pop([item]);
                  } else {
                    cubit.itemSelected(item);
                  }
                },
                hintText: AppLocalizations.of(context)!.searchHint,
                labelText: const Nullable.empty(),
              ),
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(cubit.state.selectedItems);
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(appbar.preferredSize.height + 56),
          child: appbar,
        ),
        body: BlocBuilder<ItemSearchCubit, ItemSearchState>(
          bloc: cubit,
          builder: (context, state) => CustomScrollView(
            slivers: [
              if (widget.category != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: FilterChip(
                      selected: state.categoryFilter != null,
                      avatar: const Icon(
                        Icons.label_outline_rounded,
                        size: 18,
                      ),
                      label: Text(widget.category!.name),
                      onSelected: (_) => cubit.setCategoryFilter(
                        state.categoryFilter == null ? widget.category : null,
                      ),
                    ),
                  ),
                ),
              SliverItemGridList(
                items: state.searchResults,
                selected: (item) =>
                    state.selectedItems.contains(item) ||
                    state.addedItems.contains(item),
                onLongPressed: const Nullable<void Function(Item)>.empty(),
                onPressed: Nullable((Item item) {
                  if (!widget.multiple) {
                    Navigator.of(context).pop([item]);
                  } else {
                    cubit.itemSelected(item);
                  }
                }),
              ),
              if (widget.category != null &&
                  state.otherCategoryResults.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      AppLocalizations.of(context)!.itemsOtherCategories,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      for (final item in state.otherCategoryResults)
                        ListTile(
                          leading: const Icon(Icons.label_outline_rounded),
                          title: Opacity(
                            opacity: 0.65,
                            child: Text(item.name),
                          ),
                          subtitle: Text(item.category?.name ?? ''),
                          onTap: () {
                            if (!widget.multiple) {
                              Navigator.of(context).pop([item]);
                            } else {
                              cubit.itemSelected(item);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
              if (state.createItem != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: ListTile(
                      leading: const Icon(Icons.add_circle_outline_rounded),
                      title: Text(
                        AppLocalizations.of(context)!
                            .itemCreate(state.createItem!.name),
                      ),
                      onTap: () => _handleCreate(state.createItem!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
