import 'package:material_ui/material_ui.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/shoppinglist.dart';
import 'package:houseowl/widgets/choice_scroll.dart';
import 'package:houseowl/widgets/shopping_list/shopping_list_choice_chip.dart';

enum _ShoppinglistHeaderAction {
  rename,
  delete;
}

/// Header of the shopping list page showing one chip per shopping list,
/// an inline (non-modal) "add list" input and a long-press action sheet
/// (rename / delete) per list.
class ShoppinglistHeader extends StatefulWidget {
  final List<ShoppingList> shoppinglists;
  final int? selectedShoppinglistId;
  final void Function(ShoppingList shoppinglist) onSelect;
  final Future<void> Function(String name) onAdd;
  final Future<bool> Function(ShoppingList shoppinglist) onDelete;
  final Future<bool> Function(ShoppingList shoppinglist) onRename;

  const ShoppinglistHeader({
    super.key,
    required this.shoppinglists,
    this.selectedShoppinglistId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.onRename,
  });

  @override
  State<ShoppinglistHeader> createState() => _ShoppinglistHeaderState();
}

class _ShoppinglistHeaderState extends State<ShoppinglistHeader> {
  static const double _editingFieldWidth = 180;

  final TextEditingController _addController = TextEditingController();
  final FocusNode _addFocusNode = FocusNode();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    // Programmatic blur (e.g. keyboard dismissed) reverts the input too.
    // The guard in _cancelAdding keeps this from firing while idle.
    _addFocusNode.addListener(() {
      if (!_addFocusNode.hasFocus) _cancelAdding();
    });
  }

  @override
  void dispose() {
    _addController.dispose();
    _addFocusNode.dispose();
    super.dispose();
  }

  /// The default list must not be deletable. With an explicit flag from the
  /// server we use it; if the server does not send the flag (isDefault ==
  /// null) we degrade to the previous behavior of treating the first list
  /// as the default.
  bool _isDeletable(ShoppingList shoppinglist, int index) {
    if (shoppinglist.isDefault != null) return !shoppinglist.isDefault!;
    return index != 0;
  }

  void _startAdding() {
    setState(() => _adding = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _addFocusNode.requestFocus();
    });
  }

  /// Reverts the inline input to the idle add chip. Idempotent.
  void _cancelAdding() {
    if (!_adding) return;
    _addFocusNode.unfocus();
    _addController.clear();
    setState(() => _adding = false);
  }

  /// Same rename interaction as the household settings page: a `TextDialog`
  /// prefilled with the current name. Unchanged or empty input is a no-op.
  Future<void> _rename(ShoppingList shoppinglist) async {
    final res = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return TextDialog(
          title: AppLocalizations.of(context)!.shoppingListEdit,
          doneText: AppLocalizations.of(context)!.rename,
          hintText: AppLocalizations.of(context)!.name,
          initialText: shoppinglist.name,
          isInputValid: (s) =>
              s.trim().isNotEmpty && s.trim() != shoppinglist.name,
        );
      },
    );
    if (res == null) return;
    if (!await widget.onRename(shoppinglist.copyWith(name: res.trim()))) {
      if (!mounted) return;
      showSnackbar(
        context: context,
        content: Text(AppLocalizations.of(context)!.error),
      );
    }
  }

  Future<void> _openActionSheet(ShoppingList shoppinglist, int index) async {
    final action = await showModalBottomSheet<_ShoppinglistHeaderAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  shoppinglist.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.edit_rounded),
                    label: Text(AppLocalizations.of(context)!.rename),
                    onPressed: () => Navigator.of(context)
                        .pop(_ShoppinglistHeaderAction.rename),
                  ),
                  if (_isDeletable(shoppinglist, index))
                    ActionChip(
                      avatar: const Icon(Icons.delete_rounded),
                      label: Text(AppLocalizations.of(context)!.delete),
                      onPressed: () => Navigator.of(context)
                          .pop(_ShoppinglistHeaderAction.delete),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (action == null) return;
    if (!mounted) return;
    switch (action) {
      case _ShoppinglistHeaderAction.rename:
        await _rename(shoppinglist);
        break;
      case _ShoppinglistHeaderAction.delete:
        await _delete(shoppinglist, index);
        break;
    }
  }

  Future<void> _submitAdding() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    _addFocusNode.unfocus();
    _addController.clear();
    setState(() => _adding = false);
    await widget.onAdd(name);
  }

  Future<void> _delete(ShoppingList shoppinglist, int index) async {
    if (!_isDeletable(shoppinglist, index)) return;
    final confirmed = await askForConfirmation(
      context: context,
      title: Text(AppLocalizations.of(context)!.shoppingListDelete),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text(
              AppLocalizations.of(context)!.shoppingListDeleteConfirmation(
                shoppinglist.name,
              ),
            ),
            if (shoppinglist.items.isNotEmpty) const SizedBox(height: 20),
            if (shoppinglist.items.isNotEmpty)
              Text(AppLocalizations.of(context)!
                  .shoppingListContainsEntries(shoppinglist.items.length)),
          ],
        ),
      ),
    );
    if (confirmed && !await widget.onDelete(shoppinglist)) {
      if (!mounted) return;
      showSnackbar(
        context: context,
        content: Text(AppLocalizations.of(context)!.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppinglists = List.of(widget.shoppinglists)
      ..sort((a, b) => b.items.length.compareTo(a.items.length));

    return ChoiceScroll(
      children: [
        for (var i = 0; i < shoppinglists.length; i++)
          ShoppingListChoiceChip(
            key: ValueKey<int>(shoppinglists[i].id ?? -i),
            shoppingList: shoppinglists[i],
            selected: shoppinglists[i].id == widget.selectedShoppinglistId,
            onSelected: (bool selected) {
              if (selected) widget.onSelect(shoppinglists[i]);
            },
            onLongPress: () => _openActionSheet(shoppinglists[i], i),
          ),
        if (_adding)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              // Pinned to the chip geometry so switching between the chip and
              // the input field does not change the row height.
              width: _editingFieldWidth,
              height: 32,
              child: TextField(
                controller: _addController,
                focusNode: _addFocusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitAdding(),
                // Tap-away is the single cancel path for pointer input;
                // focus loss reverts too via the focus-node listener.
                onTapOutside: (_) => _cancelAdding(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.name,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              avatar: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addShoppingList),
              onPressed: _startAdding,
            ),
          ),
      ],
    );
  }
}
