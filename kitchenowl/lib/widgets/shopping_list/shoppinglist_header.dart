import 'package:material_ui/material_ui.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/widgets/choice_scroll.dart';
import 'package:kitchenowl/widgets/shopping_list/shopping_list_choice_chip.dart';

/// Header of the shopping list page showing one chip per shopping list,
/// an inline (non-modal) "add list" input and a long-press to delete
/// non-default lists.
class ShoppinglistHeader extends StatefulWidget {
  final List<ShoppingList> shoppinglists;
  final int? selectedShoppinglistId;
  final void Function(ShoppingList shoppinglist) onSelect;
  final Future<void> Function(String name) onAdd;
  final Future<bool> Function(ShoppingList shoppinglist) onDelete;

  const ShoppinglistHeader({
    super.key,
    required this.shoppinglists,
    this.selectedShoppinglistId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
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
    if (confirmed) await widget.onDelete(shoppinglist);
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
            onLongPress: _isDeletable(shoppinglists[i], i)
                ? () => _delete(shoppinglists[i], i)
                : null,
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
