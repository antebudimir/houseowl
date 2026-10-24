import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/persons_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/person.dart';

import 'person_page.dart';

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
              final todayDate =
                  DateTime(today.year, today.month, today.day);
              final upcoming = birthdays
                  .where((e) => e.next.difference(todayDate).inDays <= 30)
                  .toList();
              final later = birthdays
                  .where((e) => e.next.difference(todayDate).inDays > 30)
                  .toList();
              body = ListView(
                children: [
                  if (upcoming.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Text(
                        AppLocalizations.of(context)!.birthdaysUpcoming,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    for (final entry in upcoming)
                      _BirthdayTile(
                        entry: entry,
                        isToday: _isToday(entry),
                      ),
                  ],
                  if (later.isNotEmpty) ...[
                    const Divider(),
                    for (final entry in later)
                      _BirthdayTile(
                        entry: entry,
                        isToday: _isToday(entry),
                      ),
                  ],
                ],
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

bool _isToday(({Person person, DateTime next}) entry) {
  final today = DateTime.now();

  return entry.next.year == today.year &&
      entry.next.month == today.month &&
      entry.next.day == today.day;
}

class _BirthdayTile extends StatelessWidget {
  final ({Person person, DateTime next}) entry;
  final bool isToday;

  const _BirthdayTile({required this.entry, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysUntil = DateTime(entry.next.year, entry.next.month, entry.next.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final subtitle = isToday
        ? AppLocalizations.of(context)!.today
        : daysUntil == 1
            ? AppLocalizations.of(context)!.tomorrow
            : '\u00b7 ${DateFormat.MMMEd().format(entry.next)} \u00b7 ${AppLocalizations.of(context)!.inDays(daysUntil)}';

    return ListTile(
      title: Text(
        entry.person.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          if ((entry.person.notes ?? "").isNotEmpty)
            Text(
              AppLocalizations.of(context)!.giftIdea(entry.person.notes!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      leading: CircleAvatar(
        child: Icon(
          isToday ? Icons.celebration_rounded : Icons.cake_rounded,
        ),
      ),
      // Jump to the underlying person record.
      onTap: () => Navigator.of(context).push<UpdateEnum>(
        MaterialPageRoute(
          builder: (ctx) => PersonPage(person: entry.person),
        ),
      ),
    );
  }
}
