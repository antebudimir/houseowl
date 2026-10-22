import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/household_page/person_add_update_page.dart';
import 'package:kitchenowl/widgets/expense_create_fab.dart';
import 'package:kitchenowl/widgets/recipe_create_fab.dart';
import 'package:kitchenowl/widgets/shoppinglist_confirm_remove_fab.dart';

enum ViewsEnum {
  items,
  recipes,
  planner,
  balances,
  persons,
  birthdays,
  more;

  String toLocalizedString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.shoppingList,
      loc.recipes,
      loc.mealPlanner,
      loc.balances,
      loc.persons,
      loc.birthdays,
      loc.more,
    ][index];
  }

  String toLocalizedShortString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.list,
      loc.recipes,
      loc.planner,
      loc.balances,
      loc.persons,
      loc.birthdays,
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
      Icons.receipt_outlined,
      Icons.calendar_today_outlined,
      Icons.account_balance_outlined,
      Icons.people_outlined,
      Icons.cake_outlined,
      App.isOffline ? Icons.cloud_off_rounded : Icons.house_rounded,
    ][index];
  }

  IconData toSelectedIcon(BuildContext context) {
    return [
      Icons.shopping_bag_rounded,
      Icons.receipt_rounded,
      Icons.calendar_today_rounded,
      Icons.account_balance_rounded,
      Icons.people_rounded,
      Icons.cake_rounded,
      App.isOffline ? Icons.cloud_off_rounded : Icons.house_rounded,
    ][index];
  }

  bool isOptional() {
    return const [
      false,
      false,
      true,
      true,
      false,
      false,
      false,
    ][index];
  }

  Widget? floatingActionButton(BuildContext context) {
    switch (this) {
      case ViewsEnum.recipes:
        return !BlocProvider.of<AuthCubit>(context, listen: true)
                .state
                .isOffline
            ? RecipeCreateFab()
            : null;
      case ViewsEnum.balances:
        return !BlocProvider.of<AuthCubit>(context, listen: true)
                .state
                .isOffline
            ? const ExpenseCreateFab()
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
      case ViewsEnum.items:
        return App.settings.shoppingListTapToRemove
            ? null
            : const ShoppingListConfirmRememoveFab();
      default:
        return null;
    }
  }

  bool isViewActive(Household household) {
    if (this == ViewsEnum.planner) {
      return household.featurePlanner ?? true;
    }
    if (this == ViewsEnum.balances) {
      return household.featureExpenses ?? true;
    }

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
      case 'recipes':
        return ViewsEnum.recipes;
      case 'planner':
        return ViewsEnum.planner;
      case 'balances':
        return ViewsEnum.balances;
      case 'persons':
        return ViewsEnum.persons;
      case 'birthdays':
        return ViewsEnum.birthdays;
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
