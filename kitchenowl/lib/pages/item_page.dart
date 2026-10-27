import 'dart:async';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:houseowl/app.dart';
import 'package:houseowl/cubits/household_cubit.dart';
import 'package:houseowl/cubits/item_edit_cubit.dart';
import 'package:houseowl/cubits/shoppinglist_cubit.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/helpers/build_context_extension.dart';
import 'package:houseowl/helpers/item_description_parser.dart';
import 'package:houseowl/models/category.dart';
import 'package:houseowl/models/item.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/shoppinglist.dart';
import 'package:houseowl/models/update_value.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/transaction_conflict_exception.dart';
import 'package:houseowl/widgets/item_popup_menu_button.dart';
import 'package:houseowl/widgets/item_wrap_menu.dart';

/// An entry in the category autocomplete: an existing category, no category,
/// or an inline "create" action for a not-yet-existing name.
class _CategoryOption {
  final Category? category;
  final String? createName;

  const _CategoryOption.value(this.category) : createName = null;
  const _CategoryOption.create(this.createName) : category = null;

  bool get isCreate => category == null && createName != null;
}

enum _CategorySelectorAction {
  rename,
  merge,
  delete;
}

class ItemPage<T extends Item> extends StatefulWidget {
  final T item;
  final ShoppingList? shoppingList;
  final List<Category> categories;
  final bool advancedView;

  const ItemPage({
    super.key,
    required this.item,
    this.shoppingList,
    this.categories = const [],
    this.advancedView = false,
  });

  @override
  _ItemPageState createState() => _ItemPageState<T>();
}

class _ItemPageState<T extends Item> extends State<ItemPage<T>> {
  final TextEditingController descController = TextEditingController();

  late ItemEditCubit<T> cubit;

  /// Working copy of the household's categories; updated in place when a
  /// category is created/renamed/merged/deleted from this page.
  late List<Category> _categories;

  @override
  void initState() {
    super.initState();
    if (widget.item is ItemWithDescription) {
      descController.text = (widget.item as ItemWithDescription).description;
    }
    _categories = List.of(widget.categories);
    cubit = ItemEditCubit<T>(
      household: context.read<HouseholdCubit>().state.household,
      item: widget.item,
      shoppingList: widget.shoppingList,
    );
  }

  @override
  void dispose() {
    cubit.close();
    descController.dispose();
    super.dispose();
  }

  Widget _buildCategorySelector(
    BuildContext context,
    ItemEditState state,
  ) {
    final loc = AppLocalizations.of(context)!;

    // Offline: read-only dropdown, matching the previous behavior.
    if (App.isOffline) {
      return DropdownButton<Category?>(
        value: state.category,
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(loc.none),
          ),
          for (final e in _categories)
            DropdownMenuItem(
              value: e,
              child: Text(e.name),
            ),
        ],
        onChanged: null,
      );
    }

    return Row(
      children: [
        Expanded(
          child: Autocomplete<_CategoryOption>(
            key: ValueKey(
              "category-selector-${state.category?.id}-${state.category?.name}",
            ),
            displayStringForOption: (option) => option.isCreate
                ? option.createName!
                : (option.category?.name ?? loc.none),
            optionsBuilder: (value) => _categoryOptions(value.text),
            onSelected: _onCategoryOptionSelected,
            initialValue: TextEditingValue(text: state.category?.name ?? ""),
            fieldViewBuilder: (
              context,
              textController,
              focusNode,
              onFieldSubmitted,
            ) =>
                TextField(
              controller: textController,
              focusNode: focusNode,
              onEditingComplete: () {
                focusNode.unfocus();
                onFieldSubmitted();
              },
            ),
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: option.isCreate
                            ? const Icon(Icons.add_circle_outline_rounded)
                            : const Icon(Icons.label_outline_rounded),
                        title: Text(
                          option.isCreate
                              ? loc.categoryCreate(option.createName!)
                              : (option.category?.name ?? loc.none),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        if (state.category != null)
          PopupMenuButton<_CategorySelectorAction>(
            tooltip: loc.categoryEdit,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => _handleCategoryAction(
              action,
              state.category!,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _CategorySelectorAction.rename,
                child: ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(loc.rename),
                ),
              ),
              PopupMenuItem(
                value: _CategorySelectorAction.merge,
                child: ListTile(
                  leading: const Icon(Icons.merge_rounded),
                  title: Text(loc.merge),
                ),
              ),
              PopupMenuItem(
                value: _CategorySelectorAction.delete,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(loc.delete),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Iterable<_CategoryOption> _categoryOptions(String query) {
    final q = query.trim().toLowerCase();
    final matches = _categories
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q))
        .map(_CategoryOption.value);
    final options = <_CategoryOption>[
      const _CategoryOption.value(null),
      ...matches,
    ];

    // Type-to-create: offer creation when nothing matches exactly.
    if (q.isNotEmpty && !_categories.any((c) => c.name.toLowerCase() == q)) {
      options.add(_CategoryOption.create(query.trim()));
    }

    return options;
  }

  Future<void> _onCategoryOptionSelected(_CategoryOption option) async {
    if (!option.isCreate) {
      cubit.setCategory(option.category);

      return;
    }
    final household = context.read<HouseholdCubit>().state.household;
    final created = await ApiService.getInstance()
        .addCategory(household, Category(name: option.createName!));
    if (!mounted) return;
    if (created == null) {
      showSnackbar(
        context: context,
        content: Text(AppLocalizations.of(context)!.error),
      );

      return;
    }
    cubit.setCategory(created);
    await _refreshCategories();
  }

  Future<void> _handleCategoryAction(
    _CategorySelectorAction action,
    Category category,
  ) async {
    final loc = AppLocalizations.of(context)!;
    switch (action) {
      case _CategorySelectorAction.rename:
        final res = await showDialog<String>(
          context: context,
          builder: (BuildContext context) => TextDialog(
            title: loc.categoryEdit,
            doneText: loc.rename,
            hintText: loc.name,
            initialText: category.name,
            isInputValid: (s) => s.trim().isNotEmpty && s != category.name,
          ),
        );
        if (res == null) return;
        final updated = category.copyWith(name: res);
        final ok = await ApiService.getInstance().updateCategory(updated);
        if (!mounted) return;
        if (ok) {
          cubit.setCategory(updated);
          await _refreshCategories();
        }
        break;
      case _CategorySelectorAction.merge:
        final other = await showDialog<Category>(
          context: context,
          builder: (context) => SelectDialog<Category>(
            title: loc.categoriesMerge,
            cancelText: loc.cancel,
            options: _categories
                .where((c) => c.id != category.id)
                .map((e) => SelectDialogOption(e, e.name))
                .toList(),
          ),
        );
        if (other == null || !mounted) return;
        final confirmed = await askForConfirmation(
          context: context,
          title: Text(loc.categoriesMerge),
          confirmText: loc.merge,
          content: Text(
            loc.itemsMergeConfirmation(category.name, other.name),
          ),
        );
        if (!confirmed || !mounted) return;
        final ok =
            await ApiService.getInstance().mergeCategories(category, other);
        if (ok && mounted) await _refreshCategories();
        break;
      case _CategorySelectorAction.delete:
        final confirmed = await askForConfirmation(
          context: context,
          title: Text(loc.categoryDelete),
          content: Text(
            loc.categoryDeleteConfirmation(category.name),
          ),
        );
        if (!confirmed || !mounted) return;
        final ok = await ApiService.getInstance().deleteCategory(category);
        if (!mounted) return;
        if (ok) {
          // Items referencing the deleted category become uncategorized
          // server-side, so follow suit locally.
          if (cubit.state.category?.id == category.id) {
            cubit.setCategory(null);
          }
          await _refreshCategories();
        }
        break;
    }
  }

  Future<void> _refreshCategories() async {
    final household = context.read<HouseholdCubit>().state.household;
    final res = await ApiService.getInstance().getCategories(household);
    if (!mounted) return;
    setState(() {
      if (res != null) _categories = res;
    });
    // Keep the household-wide category lists (grid headers etc.) in sync.
    unawaited(context.read<HouseholdCubit>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemEditCubit, ItemEditState>(
      bloc: cubit,
      buildWhen: (prev, curr) =>
          prev.hasChanged(widget.item) != curr.hasChanged(widget.item),
      builder: (context, state) => PopScope(
        canPop: !state.hasChanged(widget.item),
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop && state.hasChanged(widget.item)) {
            try {
              await cubit.saveItem();
            } on TransactionConflictException {
              if (mounted) {
                showSnackbar(
                  context: context,
                  content: Text(
                    AppLocalizations.of(context)!.itemAlreadyExists,
                  ),
                );
              }
              return;
            }
            if (mounted) {
              Navigator.of(context)
                  .pop(UpdateValue<T>(UpdateEnum.updated, cubit.item));
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: BlocBuilder<ItemEditCubit, ItemEditState>(
              bloc: cubit,
              buildWhen: (prev, curr) => prev.name != curr.name,
              builder: (context, state) => Text(state.name),
            ),
            actions: [
              if (!App.isOffline)
                ItemPopupMenuButton(
                  item: cubit.item,
                  household: context.read<HouseholdCubit>().state.household,
                  setIcon: cubit.setIcon,
                  setName: cubit.setName,
                  mergeItem: cubit.mergeItem,
                  deleteItem: () async {
                    await cubit.deleteItem();
                    if (!mounted) return;
                    Navigator.of(context)
                        .pop(const UpdateValue<Item>(UpdateEnum.deleted));
                  },
                ),
            ],
          ),
          body: Scrollbar(
            child: RefreshIndicator(
              onRefresh: cubit.refresh,
              child: CustomScrollView(
                slivers: [
                  if (widget.item is ItemWithDescription)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: TextField(
                          autofocus: true,
                          controller: descController,
                          onChanged: (s) => cubit.setDescription(s),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)),
                            ),
                            labelText:
                                AppLocalizations.of(context)!.description,
                            // suffix: IconButton(
                            //   onPressed: () {
                            //     if (descController.text.isNotEmpty) {
                            //       cubit.setDescription('');
                            //       descController.clear();
                            //     }
                            //     FocusScope.of(context).unfocus();
                            //   },
                            //   icon: Icon(
                            //     Icons.close,
                            //     color: Colors.grey,
                            //   ),
                            // ),
                          ),
                        ),
                      ),
                    ),
                  BlocBuilder<ItemEditCubit, ItemEditState>(
                    bloc: cubit,
                    buildWhen: (prev, curr) =>
                        prev.description != curr.description,
                    builder: (context, state) => (widget.item
                                is ItemWithDescription &&
                            ItemDescriptionParser.getSuggestions(
                                    state.description)
                                .isNotEmpty)
                        ? SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            sliver: SliverToBoxAdapter(
                              child: Wrap(
                                  alignment: WrapAlignment.start,
                                  runSpacing: 8,
                                  spacing: 8,
                                  children:
                                      ItemDescriptionParser.getSuggestions(
                                              state.description)
                                          .map(
                                            (s) => ActionChip(
                                              label: Text(s.$1),
                                              onPressed: () {
                                                cubit.setDescription(s.$2);
                                                descController.text = s.$2;
                                              },
                                            ),
                                          )
                                          .toList()),
                            ),
                          )
                        : SliverToBoxAdapter(),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      top: (widget.item is ItemWithDescription) ? 8 : 16,
                      bottom: (widget.advancedView) ? 8 : 16,
                      left: 16,
                      right: 16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          Text(
                            AppLocalizations.of(context)!.category,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child:
                                    BlocBuilder<ItemEditCubit, ItemEditState>(
                                  bloc: cubit,
                                  buildWhen: (prev, curr) =>
                                      prev.category != curr.category,
                                  builder: (context, state) =>
                                      _buildCategorySelector(context, state),
                                ),
                              ),
                            ],
                          ),
                          if (widget.shoppingList != null)
                            BlocBuilder<ShoppinglistCubit,
                                ShoppinglistCubitState>(
                              bloc: context.readOrNull<ShoppinglistCubit>(),
                              builder: (context, listState) {
                                // Moving only makes sense with another
                                // list to move to. Recipe ingredients are
                                // not tied to a list, so they never see
                                // this (widget.shoppingList is null).
                                final otherLists = listState
                                    .shoppinglists.values
                                    .where(
                                        (e) => e.id != widget.shoppingList!.id)
                                    .toList();
                                if (otherLists.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return DropdownButtonFormField<ShoppingList>(
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!
                                        .shoppingLists,
                                  ),
                                  items: [
                                    for (final e in otherLists)
                                      DropdownMenuItem(
                                        value: e,
                                        child: Text(e.name),
                                      ),
                                  ],
                                  onChanged: (target) async {
                                    if (target == null) return;
                                    final navigator = Navigator.of(context);
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final moved = await cubit.moveItem(
                                      target,
                                    );
                                    if (moved) {
                                      navigator.pop(UpdateValue<T>(
                                        UpdateEnum.updated,
                                        cubit.item,
                                      ));
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)!.error,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          if (widget.item is ShoppinglistItem)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                AppLocalizations.of(context)!.addedBy(context
                                        .read<HouseholdCubit>()
                                        .state
                                        .household
                                        .member
                                        ?.firstWhereOrNull(
                                          (e) =>
                                              e.id ==
                                              (widget.item as ShoppinglistItem)
                                                  .createdById,
                                        )
                                        ?.name ??
                                    AppLocalizations.of(context)!.other),
                              ),
                              trailing: (widget.item as ShoppinglistItem)
                                          .createdAt !=
                                      null
                                  ? Text(
                                      DateFormat.yMMMEd().add_jm().format(
                                            (widget.item as ShoppinglistItem)
                                                .createdAt!,
                                          ),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.advancedView)
                    BlocBuilder<ItemEditCubit, ItemEditState>(
                      bloc: cubit,
                      builder: (context, state) => SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (!App.isOffline)
                              ItemWrapMenu(
                                item: cubit.item,
                                household: context
                                    .read<HouseholdCubit>()
                                    .state
                                    .household,
                                setIcon: cubit.setIcon,
                                setName: cubit.setName,
                                mergeItem: cubit.mergeItem,
                                deleteItem: () async {
                                  await cubit.deleteItem();
                                  if (!mounted) return;
                                  Navigator.of(context).pop(
                                      const UpdateValue<Item>(
                                          UpdateEnum.deleted));
                                },
                              ),
                            const Divider(height: 32),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                AppLocalizations.of(context)!.about,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title:
                                  Text(AppLocalizations.of(context)!.ordering),
                              trailing: Text(widget.item.ordering.toString()),
                            ),
                            if (state.icon != null)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(AppLocalizations.of(context)!.icon),
                                trailing: Text(state.icon ?? ""),
                              ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                  AppLocalizations.of(context)!.defaultWord),
                              trailing: Text(widget.item.isDefault.toString()),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                  AppLocalizations.of(context)!.defaultKey),
                              trailing: Text(widget.item.defaultKey ?? ""),
                            ),
                            const Divider(),
                          ]),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child:
                        SizedBox(height: MediaQuery.paddingOf(context).bottom),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
