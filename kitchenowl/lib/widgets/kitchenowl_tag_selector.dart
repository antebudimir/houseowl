import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:material_ui/material_ui.dart';

/// The shared tag selection component used by notes.
/// Renders the household's tags as selectable [FilterChip]s plus an
/// add-tag button backed by a [TextDialog].
class KitchenOwlTagSelector extends StatelessWidget {
  final Set<Tag> tags;
  final Set<Tag> selectedTags;
  final void Function(Tag tag, bool selected) onSelect;
  final void Function(String name) onAdd;

  const KitchenOwlTagSelector({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = tags
        .map<Widget>(
          (e) => FilterChip(
            label: Text(
              e.name,
              style: TextStyle(
                color: selectedTags.contains(e)
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
            ),
            selected: selectedTags.contains(e),
            onSelected: (selected) => onSelect(e, selected),
            selectedColor: Theme.of(context).colorScheme.secondary,
          ),
        )
        .toList();

    Widget widget = Tooltip(
      message: AppLocalizations.of(context)!.addTag,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () async {
            final res = await showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return TextDialog(
                  title: AppLocalizations.of(context)!.addTag,
                  doneText: AppLocalizations.of(context)!.add,
                  hintText: AppLocalizations.of(context)!.name,
                  isInputValid: (s) => s.isNotEmpty,
                );
              },
            );
            if (res != null) {
              onAdd(res);
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );

    if (children.isEmpty) {
      children = [Text(AppLocalizations.of(context)!.noTags)];
    }

    // Wrap everything in a plain Flutter [Material]: pages hosting this
    // selector may use the material_ui fork, whose Scaffold provides the
    // fork's own Material type that Flutter widgets cannot find.
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          runSpacing: 8,
          spacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children + [widget],
        ),
      ),
    );
  }
}
