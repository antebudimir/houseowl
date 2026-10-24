import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/persons_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class BirthdaysPage extends StatelessWidget {
  const BirthdaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<PersonsCubit>(context);

    return SafeArea(
      child: BlocBuilder<PersonsCubit, PersonsCubitState>(
        bloc: cubit,
        builder: (context, state) {
          final Widget body;
          if (state is LoadingPersonsCubitState) {
            body = const Center(child: CircularProgressIndicator());
          } else {
            final birthdays = state.persons
                .where((e) => e.birthday != null)
                .map((e) => (person: e, next: e.nextBirthdayOccurrence()!))
                .toList()
              ..sort((a, b) => a.next.compareTo(b.next));
            if (birthdays.isEmpty) {
              body = EmptyState(
                icon: Icons.cake_outlined,
                message: AppLocalizations.of(context)!.emptyBirthdayList,
              );
            } else {
              final today = DateTime.now();
              body = ListView.builder(
                itemCount: birthdays.length,
                itemBuilder: (context, i) {
                  final entry = birthdays[i];
                  final isToday = entry.next.year == today.year &&
                      entry.next.month == today.month &&
                      entry.next.day == today.day;
                  final daysUntil = DateTime(
                    entry.next.year,
                    entry.next.month,
                    entry.next.day,
                  )
                      .difference(DateTime(today.year, today.month, today.day))
                      .inDays;
                  final subtitle = isToday
                      ? AppLocalizations.of(context)!.today
                      : daysUntil == 1
                          ? AppLocalizations.of(context)!.tomorrow
                          : '${DateFormat.MMMEd().format(entry.next)} · ${AppLocalizations.of(context)!.inDays(daysUntil)}';

                  return ListTile(
                    title: Text(
                      entry.person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(subtitle),
                    leading: CircleAvatar(
                      child: Icon(
                        isToday
                            ? Icons.celebration_rounded
                            : Icons.cake_rounded,
                      ),
                    ),
                  );
                },
              );
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.birthdays,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}
