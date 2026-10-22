import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_about_cubit.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HouseholdAboutPage extends StatefulWidget {
  final Household household;

  const HouseholdAboutPage({super.key, required this.household});

  @override
  State<HouseholdAboutPage> createState() => _HouseholdAboutPageState();
}

class _HouseholdAboutPageState extends State<HouseholdAboutPage> {
  late HouseholdAboutCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdAboutCubit(widget.household);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<HouseholdAboutCubit, HouseholdAboutState>(
        bloc: cubit,
        builder: (context, state) => CustomScrollView(
          slivers: [
            SliverCrossAxisConstrained(
              maxCrossAxisExtent: 1600,
              child: SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Center(
                        child: HouseholdCircleAvatar(
                          household: state.household,
                          radius: 45,
                          textScaler: TextScaler.linear(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              state.household.name,
                              style: TextTheme.of(context).displaySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (state.household.verified)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.verified_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      if (state.household.description?.isNotEmpty ?? false)
                        Text(
                          state.household.description!,
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),
                      if (state.household.link != null &&
                          state.household.link!.isNotEmpty &&
                          isValidUrl(state.household.link!))
                        ListTile(
                          title: Text(state.household.link!),
                          leading: Icon(Icons.link),
                          onTap: () => openUrl(context, state.household.link!),
                        ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }
}
