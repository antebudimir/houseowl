import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/planned_buys_cubit.dart';
import 'package:kitchenowl/enums/buy_status.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/planned_buy.dart';
import 'package:kitchenowl/pages/household_page/planned_buy_add_update_page.dart';

class PlannedBuysPage extends StatelessWidget {
  const PlannedBuysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<PlannedBuysCubit>(context);

    return SafeArea(
      child: BlocBuilder<PlannedBuysCubit, PlannedBuysCubitState>(
        builder: (context, state) {
          final Widget body;
          if (state is LoadingPlannedBuysCubitState) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.buys.isEmpty) {
            body = Center(
              child: Text(
                AppLocalizations.of(context)!.plannedBuyEmpty,
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final sections = <BuyStatus, List<PlannedBuy>>{};
            for (final buy in state.buys) {
              sections.putIfAbsent(buy.status, () => []).add(buy);
            }

            body = ListView(
              children: [
                for (final status in BuyStatus.values)
                  if (sections.containsKey(status)) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Row(
                        children: [
                          Icon(
                            status.toIcon(),
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status.toLocalizedString(context),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    for (final buy in sections[status]!)
                      _PlannedBuyTile(
                        buy: buy,
                        onEdit: () async {
                          final res = await Navigator.of(context)
                              .push<UpdateEnum>(
                            MaterialPageRoute(
                              builder: (ctx) => BlocProvider.value(
                                value: cubit,
                                child: PlannedBuyAddUpdatePage(
                                  household: BlocProvider.of<HouseholdCubit>(
                                          context)
                                      .state
                                      .household,
                                  plannedBuy: buy,
                                ),
                              ),
                            ),
                          );
                          if (res == UpdateEnum.updated) cubit.refresh();
                        },
                        onDelete: () => _confirmDelete(context, cubit, buy),
                      ),
                  ],
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: cubit.refresh,
            child: body,
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PlannedBuysCubit cubit,
    PlannedBuy buy,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(ctx)!.plannedBuyDeleteConfirmation(buy.name),
        ),
        content: Text(buy.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(ctx)!.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.deletePlannedBuy(buy);
    }
  }
}

class _PlannedBuyTile extends StatelessWidget {
  final PlannedBuy buy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlannedBuyTile({
    required this.buy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitles = <String>[
      if (buy.category != null && buy.category!.isNotEmpty) buy.category!,
      if (buy.assignee != null) buy.assignee!.name,
    ];

    return ListTile(
      title: Text(
        buy.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitles.isEmpty
          ? null
          : Text(
              subtitles.join(" · "),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: buy.isAcquired && buy.actualPrice != null
          ? Text(buy.actualPrice!.toStringAsFixed(2))
          : (buy.priority > 0
              ? Icon(Icons.flag_rounded, size: 20)
              : null),
      onTap: onEdit,
      onLongPress: onDelete,
    );
  }
}
