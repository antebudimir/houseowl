import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/app.dart';
import 'package:houseowl/cubits/auth_cubit.dart';
import 'package:houseowl/cubits/household_cubit.dart';
import 'package:houseowl/cubits/persons_cubit.dart';
import 'package:houseowl/cubits/planned_buys_cubit.dart';
import 'package:houseowl/cubits/notes_cubit.dart';
import 'package:houseowl/cubits/documents_cubit.dart';
import 'package:houseowl/cubits/loyalty_cards_cubit.dart';
import 'package:houseowl/cubits/tasks_cubit.dart';
import 'package:houseowl/cubits/events_cubit.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/pages/household_page/document_add_update_page.dart';
import 'package:houseowl/pages/household_page/loyalty_card_add_update_page.dart';
import 'package:houseowl/pages/household_page/note_add_update_page.dart';
import 'package:houseowl/pages/household_page/person_add_update_page.dart';
import 'package:houseowl/pages/household_page/planned_buy_add_update_page.dart';
import 'package:houseowl/pages/household_page/event_add_update_page.dart';
import 'package:houseowl/pages/household_page/task_add_update_page.dart';
import 'package:houseowl/widgets/shoppinglist_confirm_remove_fab.dart';

enum ViewsEnum {
  items,
  planned,
  persons,
  birthdays,
  notes,
  documents,
  loyaltyCards,
  tasks,
  events,
  more;

  String toLocalizedString(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      loc.shoppingList,
      loc.planned,
      loc.persons,
      loc.birthdays,
      loc.notes,
      loc.documents,
      loc.loyaltyCards,
      loc.tasks,
      loc.events,
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
      loc.documents,
      loc.loyaltyCards,
      loc.tasks,
      loc.events,
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
      Icons.folder_outlined,
      Icons.loyalty_outlined,
      Icons.checklist_outlined,
      Icons.event_outlined,
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
      Icons.folder_rounded,
      Icons.loyalty_rounded,
      Icons.checklist_rounded,
      Icons.event_rounded,
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
      true,
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
                    builder: (ctx) => BlocProvider.value(
                      value: BlocProvider.of<PlannedBuysCubit>(context),
                      child: PlannedBuyAddUpdatePage(
                        household: BlocProvider.of<HouseholdCubit>(context)
                            .state
                            .household,
                      ),
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
                    builder: (ctx) => BlocProvider.value(
                      value: BlocProvider.of<TasksCubit>(context),
                      child: TaskAddUpdatePage(
                        household: BlocProvider.of<HouseholdCubit>(context)
                            .state
                            .household,
                      ),
                    ),
                  ),
                ),
                child: const Icon(Icons.add_rounded),
              )
            : null;
      case ViewsEnum.events:
        return !BlocProvider.of<AuthCubit>(context, listen: true)
                .state
                .isOffline
            ? FloatingActionButton(
                tooltip: AppLocalizations.of(context)!.eventAdd,
                onPressed: () => Navigator.of(context).push<UpdateEnum>(
                  MaterialPageRoute(
                    builder: (ctx) => BlocProvider.value(
                      value: BlocProvider.of<EventsCubit>(context),
                      child: EventAddUpdatePage(
                        household: BlocProvider.of<HouseholdCubit>(context)
                            .state
                            .household,
                      ),
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
                    builder: (ctx) => BlocProvider.value(
                      value: BlocProvider.of<PersonsCubit>(context),
                      child: const PersonAddUpdatePage(),
                    ),
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
              builder: (ctx) => BlocProvider.value(
                value: BlocProvider.of<NotesCubit>(context),
                child: NoteAddUpdatePage(
                  household:
                      BlocProvider.of<HouseholdCubit>(context).state.household,
                ),
              ),
            ),
          ),
          child: const Icon(Icons.add_rounded),
        );
      case ViewsEnum.documents:
        return FloatingActionButton(
          tooltip: AppLocalizations.of(context)!.documentAdd,
          onPressed: () => Navigator.of(context).push<UpdateEnum>(
            MaterialPageRoute(
              builder: (ctx) => BlocProvider.value(
                value: BlocProvider.of<DocumentsCubit>(context),
                child: DocumentAddUpdatePage(
                  household:
                      BlocProvider.of<HouseholdCubit>(context).state.household,
                ),
              ),
            ),
          ),
          child: const Icon(Icons.add_rounded),
        );
      case ViewsEnum.loyaltyCards:
        return FloatingActionButton(
          tooltip: AppLocalizations.of(context)!.loyaltyCardAdd,
          onPressed: () => Navigator.of(context).push<UpdateEnum>(
            MaterialPageRoute(
              builder: (ctx) => BlocProvider.value(
                value: BlocProvider.of<LoyaltyCardsCubit>(context),
                child: LoyaltyCardAddUpdatePage(
                  household:
                      BlocProvider.of<HouseholdCubit>(context).state.household,
                ),
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
    // 'more' is the settings entry point and always visible.
    return this == ViewsEnum.more ||
        !(household.hiddenViews?.contains(this) ?? false);
  }

  /// Adds all missing views.
  ///
  /// View orderings are persisted as view name strings (see
  /// Household.viewOrdering), so appending a new enum value never needs a
  /// data migration — old orderings simply gain the new view at the end
  /// via this method.
  static List<ViewsEnum> addMissing(Iterable<ViewsEnum> iterable) {
    final l = iterable.toList();
    l.addAll(ViewsEnum.values.where((e) => !iterable.contains(e)));

    return l;
  }

  /// The household's full navigable view ordering: the stored `view_ordering`
  /// (defaulting to the enum order), with any unknown views appended, minus
  /// hidden views. 'more' is kept — callers decide whether to show it as a
  /// tab (it never is) or as a sheet entry point.
  static List<ViewsEnum> orderedViews(Household household) {
    final List<ViewsEnum>? stored = household.viewOrdering;
    final List<ViewsEnum> ordering = (stored == null || stored.isEmpty)
        ? ViewsEnum.values
        : addMissing(stored);
    return ordering.where((e) => e.isViewActive(household)).toList();
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
      case 'documents':
        return ViewsEnum.documents;
      case 'loyaltyCards':
        return ViewsEnum.loyaltyCards;
      case 'tasks':
        return ViewsEnum.tasks;
      case 'events':
        return ViewsEnum.events;
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
