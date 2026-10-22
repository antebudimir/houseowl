import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/planned_buys_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/persons_cubit.dart';
import 'package:kitchenowl/cubits/notes_cubit.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/household_page/household_drawer.dart';
import 'package:kitchenowl/pages/household_page/household_navigation_rail.dart';
import 'package:kitchenowl/pages/household_page/more.dart';
import 'package:kitchenowl/pages/page_not_found.dart';
import 'package:kitchenowl/router.dart';
import 'package:responsive_builder/responsive_builder.dart';

class HouseholdPage extends StatefulWidget {
  final Household household;
  final Widget child;
  const HouseholdPage({
    super.key,
    required this.household,
    required this.child,
  });

  @override
  _HouseholdPageState createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage>
    with WidgetsBindingObserver, RouteAware {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  RouteObserver? routeObserver;

  late final HouseholdCubit householdCubit;
  late final ShoppinglistCubit shoppingListCubit;
  late final PlannedBuysCubit plannedBuysCubit;
  late final PersonsCubit personsCubit;
  late final NotesCubit notesCubit;

  @override
  void initState() {
    super.initState();
    householdCubit = HouseholdCubit(widget.household);
    shoppingListCubit = ShoppinglistCubit(widget.household);
    plannedBuysCubit = PlannedBuysCubit(widget.household);
    personsCubit = PersonsCubit(widget.household);
    notesCubit = NotesCubit(widget.household);
    WidgetsBinding.instance.addObserver(this);

    if (router.state.uri.path.contains("planned")) {
      plannedBuysCubit.refresh();
    }
    if (router.state.uri.path.contains("persons") ||
        router.state.uri.path.contains("birthdays")) {
      personsCubit.refresh();
    }
    if (router.state.uri.path.contains("notes")) {
      notesCubit.refresh();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newRouteObserver =
        RepositoryProvider.of<RouteObserver<ModalRoute>>(context);
    if (routeObserver != newRouteObserver) {
      routeObserver?.unsubscribe(this);
      newRouteObserver.subscribe(this, ModalRoute.of(context)!);
      routeObserver = newRouteObserver;
    }
  }

  @override
  void dispose() {
    routeObserver?.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    householdCubit.close();
    shoppingListCubit.close();
    plannedBuysCubit.close();
    personsCubit.close();
    notesCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      householdCubit.refresh();
      shoppingListCubit.refresh();
      personsCubit.refresh();
      notesCubit.refresh();
    }
  }

  @override
  void didPopNext() {
    if (router.state.uri.path.contains("persons") ||
        router.state.uri.path.contains("birthdays")) {
      personsCubit.refresh();
    }
    if (router.state.uri.path.contains("notes")) {
      notesCubit.refresh();
    }
    if (router.state.uri.path.contains("planned")) {
      plannedBuysCubit.refresh();
    }
  }

  void _onItemTapped(
    BuildContext context,
    ViewsEnum tapped,
    ViewsEnum current,
  ) {
    householdCubit.refresh();
    switch (tapped) {
      case ViewsEnum.items:
        if (tapped == current) {
          shoppingListCubit.refresh(query: '');
        } else {
          shoppingListCubit.refresh();
        }
        break;
      case ViewsEnum.planned:
        plannedBuysCubit.refresh();
        break;
      case ViewsEnum.persons:
      case ViewsEnum.birthdays:
        personsCubit.refresh();
        break;
      case ViewsEnum.notes:
        notesCubit.refresh();
        break;
      case ViewsEnum.more:
        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => BlocProvider.value(
            value: householdCubit,
            child: MorePage(),
          ),
        );
        return;
    }
    context.go("/household/${widget.household.id}/${tapped.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: householdCubit),
        BlocProvider.value(value: shoppingListCubit),
        BlocProvider.value(value: plannedBuysCubit),
        BlocProvider.value(value: personsCubit),
        BlocProvider.value(value: notesCubit),
      ],
      child: BlocConsumer<HouseholdCubit, HouseholdState>(
        listener: (context, state) {
          if (state is NotFoundHouseholdState && mounted) {
            return context.go("/household");
          }
          List<ViewsEnum> pages =
              (state.household.viewOrdering ?? ViewsEnum.values)
                  .where((e) => e.isViewActive(state.household))
                  .toList();

          int _selectedIndex = pages.indexWhere(
            (e) => GoRouterState.of(context).uri.path.contains(e.toString()),
          );

          if (_selectedIndex < 0 && mounted) {
            context.go(
              "/household/${state.household.id}/${state.household.viewOrdering?.firstOrNull.toString() ?? "items"}",
            );
          }
        },
        builder: (context, state) {
          List<ViewsEnum> pages =
              (state.household.viewOrdering ?? ViewsEnum.values)
                  .where((e) => e.isViewActive(state.household))
                  .toList();

          int _selectedIndex = pages.indexWhere(
            (e) => GoRouterState.of(context).uri.path.contains(e.toString()),
          );

          if (_selectedIndex < 0 || state is NotFoundHouseholdState) {
            return const PageNotFound();
          }

          final bool useBottomNavigationBar = getValueForScreenType<bool>(
            context: context,
            mobile: true,
            tablet: false,
            desktop: false,
          );

          Widget body = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 1600),
              child: widget.child,
            ),
          );

          if (!useBottomNavigationBar) {
            final bool extendedRail = getValueForScreenType<bool>(
              context: context,
              mobile: false,
              tablet: false,
              desktop: true,
            );
            body = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeArea(
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) => HouseholdNavigationRail(
                      extendedRail: extendedRail,
                      pages: pages,
                      onPageSelected: _onItemTapped,
                      openDrawer: scaffoldKey.currentState!.openDrawer,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                ),
                Expanded(child: body),
              ],
            );
          }

          return Scaffold(
            key: scaffoldKey,
            body: body,
            floatingActionButton:
                pages[_selectedIndex].floatingActionButton(context),
            drawer: HouseholdDrawer(
              onPageSelected: _onItemTapped,
              pages: pages,
              selectedIndex: _selectedIndex,
              popOnSelection: true,
            ),
            drawerEnableOpenDragGesture: false,
            bottomNavigationBar: useBottomNavigationBar
                ? BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) => NavigationBar(
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      destinations: pages
                          .map((e) => NavigationDestination(
                                icon: e.toIconWidget(context) ??
                                    Icon(e.toIcon(context)),
                                selectedIcon: Icon(e.toSelectedIcon(context)),
                                label: e.toLocalizedShortString(context),
                                tooltip: e.toLocalizedString(context),
                              ))
                          .take(5)
                          .toList(),
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (i) => _onItemTapped(
                        context,
                        pages[i],
                        pages[_selectedIndex],
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}
