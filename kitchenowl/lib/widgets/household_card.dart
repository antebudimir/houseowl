import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:houseowl/cubits/auth_cubit.dart';
import 'package:houseowl/cubits/household_list_cubit.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/widgets/avatar_list.dart';
import 'package:houseowl/widgets/household_image.dart';

class HouseholdCard extends StatelessWidget {
  final Household household;

  const HouseholdCard({super.key, required this.household});

  @override
  Widget build(BuildContext context) {
    final user = BlocProvider.of<AuthCubit>(context).getUser();
    final member = household.member?.firstWhereOrNull(
      (m) => user?.id == m.id,
    );

    return Card(
      child: InkWell(
        onTap: () => context.go(
          '/household/${household.id}/${household.viewOrdering?.firstOrNull.toString()}',
          extra: household,
        ),
        onLongPress: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: Text(household.name),
                  subtitle: household.member == null
                      ? null
                      : Text(
                          "${AppLocalizations.of(ctx)!.members}: ${household.member!.length}",
                        ),
                ),
                const Divider(),
                LoadingElevatedButton(
                  onPressed: member == null
                      ? null
                      : () async {
                          await BlocProvider.of<HouseholdListCubit>(context)
                              .leaveHousehold(household, member);
                          Navigator.of(ctx).pop();
                        },
                  child: Text(AppLocalizations.of(ctx)!.householdLeave),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (household.image?.isNotEmpty ?? false)
                    HouseholdImage(
                      household: household,
                      enableMembersTap: false,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(
                      household.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (user != null && member != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Text(
                        member.username,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            if (household.image?.isEmpty ?? true && household.member != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                child: AvatarList(
                  users: household.member!,
                  radius: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
