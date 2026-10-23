import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/events_cubit.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/event.dart';
import 'package:kitchenowl/pages/household_page/event_add_update_page.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<EventsCubit>(context);

    return SafeArea(
      child: BlocBuilder<EventsCubit, EventsCubitState>(
        builder: (context, state) {
          final Widget body;
          if (state is LoadingEventsCubitState) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.events.isEmpty) {
            body = Center(
              child: Text(AppLocalizations.of(context)!.noEvents),
            );
          } else {
            body = _CalendarAgenda(
              events: state.events,
              onEdit: (event) => _edit(context, cubit, event),
              onDelete: (event) => _confirmDelete(context, cubit, event),
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

  Future<void> _edit(
    BuildContext context,
    EventsCubit cubit,
    Event event,
  ) async {
    final res = await Navigator.of(context).push<UpdateEnum>(
      MaterialPageRoute(
        builder: (ctx) => EventAddUpdatePage(
          household: BlocProvider.of<HouseholdCubit>(context).state.household,
          event: event,
        ),
      ),
    );
    if (res == UpdateEnum.updated) cubit.refresh();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EventsCubit cubit,
    Event event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(ctx)!.eventDeleteConfirmation(event.name),
        ),
        content: Text(event.name),
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
      await cubit.deleteEvent(event);
    }
  }
}

/// Month calendar with markers plus an agenda list for the selected day.
/// All-day events are bucketed by their local start date, matching how the
/// server encodes them ([local midnight, next local midnight)).
class _CalendarAgenda extends StatefulWidget {
  final List<Event> events;
  final void Function(Event) onEdit;
  final void Function(Event) onDelete;

  const _CalendarAgenda({
    required this.events,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CalendarAgenda> createState() => _CalendarAgendaState();
}

class _CalendarAgendaState extends State<_CalendarAgenda> {
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  DateTime _dayOf(Event event) {
    final local = event.start.toLocal();

    return DateTime(local.year, local.month, local.day);
  }

  Map<DateTime, List<Event>> get _eventsByDay {
    final map = <DateTime, List<Event>>{};
    for (final event in widget.events) {
      map.putIfAbsent(_dayOf(event), () => []).add(event);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final byDay = _eventsByDay;
    final normalized = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final agenda = byDay[normalized] ?? const <Event>[];
    final loc = AppLocalizations.of(context)!;

    return ListView(
      children: [
        TableCalendar<Event>(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
          focusedDay: _selectedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) =>
              setState(() => _calendarFormat = format),
          eventLoader: (day) =>
              byDay[DateTime(day.year, day.month, day.day)] ?? const [],
          onPageChanged: (focused) => setState(() => _selectedDay = focused),
          onDaySelected: (selected, focused) =>
              setState(() => _selectedDay = selected),
          locale: Localizations.localeOf(context).toString(),
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerStyle: const HeaderStyle(formatButtonVisible: false),
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Divider(),
        if (agenda.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                loc.noEvents,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          for (final event in agenda)
            ListTile(
              leading: const Icon(Icons.event_rounded),
              title: Text(
                event.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(_subtitle(context, event)),
              onTap: () => widget.onEdit(event),
              onLongPress: () => widget.onDelete(event),
            ),
      ],
    );
  }

  String _subtitle(BuildContext context, Event event) {
    final loc = AppLocalizations.of(context)!;
    final parts = <String>[
      if (event.allDay)
        loc.allDay
      else
        MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(event.start.toLocal()),
        ),
      if (event.location != null && event.location!.isNotEmpty) event.location!,
      if (event.attendees.isNotEmpty)
        event.attendees.map((p) => p.name).join(", "),
    ];

    return parts.join(" · ");
  }
}
