import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/household_page/note_add_update_page.dart';
import 'package:kitchenowl/pages/household_page/person_add_update_page.dart';
import 'package:kitchenowl/pages/household_page/planned_buy_add_update_page.dart';
import 'package:kitchenowl/pages/household_page/task_add_update_page.dart';
import 'package:kitchenowl/widgets/shoppinglist_confirm_remove_fab.dart';

enum ViewsEnum {
  items,
  planned,
  persons,
  birthdays,
  notes,
  tasks,
  more;

  String toLocalizedString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.shoppingList,
      loc.planned,
      loc.persons,
      loc.birthdays,
      loc.notes,
      loc.tasks,
      loc.more,
    ][index];
  }

  String toLocalizedShortString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.list,
      loc.planned,
      loc.persons,
      loc.birthdays,
      loc.notes,
      loc.tasks,
      loc.more,
    ][index];
  }

  Widget? toIconWidget(BuildContext context) {
    if (this == ViewsEnum.more) {
      Household? household = context.read<HouseholdCubit>().state.household;
      if (!App.isOffline && household.image != null)
        return CircleAvatar(
          radius: 16,
          foregroundImage: getImageProvider(
            context,
            household.image!,
          ),
        );
    }
    return null;
  }

  IconData toIcon(BuildContext context) {
    return [
      Icons.shopping_bag_outlined,
      Icons.add_shopping_cart_outlined,
      Icons.people_outlined,
      Icons.cake_outlined,
      Icons.sticky_note_2_outlined,
      Icons.checklist_outlined,
      App.isOffline ? Icons.cloud_off_rounded : Icons.house_rounded,
    ][index];
  }

  IconData toSelectedIcon(BuildContext context) {
    return [
      Icons.shopping_bag_rounded,
      Icons.add_shopping_cart_rounded,
      Icons.people_rounded,
      Icons.cake_rounded,
      Icons.sticky_note_2_rounded,
      Icons.checklist_rounded,
      App.isOffline ? Icons.cloud_off_rounded : Icons.house_rounded,
    ][index];
  }

  bool isOptional() {
    return const [
      false,
      true,
      false,
      false,
      true,
      true,
    ][index];
  }

  Widget? floatingActionButton(BuildContext context) {
    switch (this) {
      case ViewsEnum.planned:
        return !BlocProvider.of<AuthCubit>(context, listen: true)
                .state
                .isOffline
            ? FloatingActionButton(
                tooltip: AppLocalizations.of(context)!.plannedBuyAdd,
                onPressed: () => Navigator.of(context).push<UpdateEnum>(
                  MaterialPageRoute(
                    builder: (ctx) => PlannedBuyAddUpdatePage(
                      household: BlocProvider.of<HouseholdCubit>(context)
                          .state
                          .household,
                    ),
                  ),
                ),
                child: const Icon(Icons.add_rounded),
              )
            : null;
      case ViewsEnum.tasks:
        return !BlocProvider.of<AuthCubit>(context, listen: true)
                .state
                .isOffline
            ? FloatingActionButton(
                tooltip: AppLocalizations.of(context)!.taskAdd,
                onPressed: () => Navigator.of(context).push<UpdateEnum>(
                  MaterialPageRoute(
                    builder: (ctx) => TaskAddUpdatePage(
                      household: BlocProvider.of<HouseholdCubit>(context)
                          .state
                          .household,
                    ),
                  ),
                ),
                child: const Icon(Icons.add_rounded),
              )
            : null;
      case ViewsEnum.persons:
        return !BlocProvider.of<AuthCubit>(context, listen: true)
                .state
                .isOffline
            ? FloatingActionButton(
                tooltip: AppLocalizations.of(context)!.personAdd,
                onPressed: () => Navigator.of(context).push<UpdateEnum>(
                  MaterialPageRoute(
                    builder: (ctx) => const PersonAddUpdatePage(),
                  ),
                ),
                child: const Icon(Icons.add_rounded),
              )
            : null;
      case ViewsEnum.notes:
        return FloatingActionButton(
          tooltip: AppLocalizations.of(context)!.noteAdd,
          onPressed: () => Navigator.of(context).push<UpdateEnum>(
            MaterialPageRoute(
              builder: (ctx) => NoteAddUpdatePage(
                household: BlocProvider.of<HouseholdCubit>(context)
                    .state
                    .household,
              ),
            ),
          ),
          child: const Icon(Icons.add_rounded),
        );
      case ViewsEnum.items:
        return App.settings.shoppingListTapToRemove
            ? null
            : const ShoppingListConfirmRememoveFab();
      default:
        return null;
    }
  }

  bool isViewActive(Household household) {
    return true;
  }

  /// Adds all missing views
  static List<ViewsEnum> addMissing(Iterable<ViewsEnum> iterable) {
    final l = iterable.toList();
    l.addAll(ViewsEnum.values.where((e) => !iterable.contains(e)));

    return l;
  }

  static ViewsEnum? parse(String str) {
    switch (str) {
      case 'items':
        return ViewsEnum.items;
      case 'planned':
      // Households saved before the expense system was removed keep their
      // view ordering; the old balances view became the planned buys view.
      case 'balances':
        return ViewsEnum.planned;
      case 'persons':
        return ViewsEnum.persons;
      case 'birthdays':
        return ViewsEnum.birthdays;
      case 'notes':
        return ViewsEnum.notes;
      case 'tasks':
        return ViewsEnum.tasks;
      case 'profile':
      case 'more':
        return ViewsEnum.more;
      default:
        return null;
    }
  }

  @override
  String toString() {
    return name;
  }
}
