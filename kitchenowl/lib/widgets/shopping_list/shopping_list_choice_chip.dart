import 'package:material_ui/material_ui.dart';
import 'package:houseowl/models/shoppinglist.dart';

class ShoppingListChoiceChip extends StatelessWidget {
  final ShoppingList shoppingList;
  final bool selected;
  final void Function(bool)? onSelected;
  final void Function()? onLongPress;

  const ShoppingListChoiceChip({
    super.key,
    required this.shoppingList,
    this.selected = false,
    this.onSelected,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ChoiceChip(
          showCheckmark: false,
          label: Text(
            shoppingList.name +
                (shoppingList.items.isNotEmpty
                    ? " (${shoppingList.items.length})"
                    : ""),
            style: TextStyle(
              color: selected ? Theme.of(context).colorScheme.onPrimary : null,
            ),
          ),
          selected: selected,
          elevation: shoppingList.items.isNotEmpty ? 2 : 0,
          selectedColor: Theme.of(context).colorScheme.secondary,
          onSelected: onSelected,
        ),
      ),
    );
  }
}
