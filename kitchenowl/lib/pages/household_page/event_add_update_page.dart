import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/cubits/event_add_update_cubit.dart';
import 'package:houseowl/cubits/events_cubit.dart';
import 'package:houseowl/enums/update_enum.dart';
import 'package:houseowl/kitchenowl.dart';
import 'package:houseowl/models/event.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/person.dart';

class EventAddUpdatePage extends StatefulWidget {
  final Household household;
  final Event? event;

  const EventAddUpdatePage({
    super.key,
    required this.household,
    this.event,
  });

  @override
  State<EventAddUpdatePage> createState() => _EventAddUpdatePageState();
}

class _EventAddUpdatePageState extends State<EventAddUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  late final EventAddUpdateCubit _cubit;
  bool _isLoading = false;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _nameController = TextEditingController(text: widget.event?.name ?? "");
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? "");
    _locationController =
        TextEditingController(text: widget.event?.location ?? "");
    // Default slot: the next full hour, one hour long.
    _start = widget.event?.start.toLocal() ??
        DateTime(now.year, now.month, now.day, now.hour + 1);
    _end = widget.event?.end.toLocal() ?? _start.add(const Duration(hours: 1));
    _allDay = widget.event?.allDay ?? false;
    _cubit = EventAddUpdateCubit(
      widget.household,
      selectedPersons:
          Set<Person>.from(widget.event?.attendees ?? const <Person>[]),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (selected != null) {
      setState(() {
        final duration = _end.difference(_start);
        _start = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _start.hour,
          _start.minute,
        );
        _end = _start.add(duration);
      });
      _checkConflicts();
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (selected != null) {
      setState(() {
        final target = DateTime(
          current.year,
          current.month,
          current.day,
          selected.hour,
          selected.minute,
        );
        if (isStart) {
          _start = target;
          if (!_end.isAfter(_start)) {
            _end = _start.add(const Duration(hours: 1));
          }
        } else {
          _end = target;
        }
      });
      _checkConflicts();
    }
  }

  void _checkConflicts() {
    _cubit.checkConflicts(
      start: _start.toUtc(),
      end: _end.toUtc(),
      excludeId: widget.event?.id,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final event = Event(
      id: widget.event?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      start: _start.toUtc(),
      end: _end.toUtc(),
      allDay: _allDay,
      attendees: _cubit.state.selectedPersons.toList(),
    );

    final cubit = BlocProvider.of<EventsCubit>(context, listen: false);
    final res = isEditing
        ? await cubit.updateEvent(event)
        : await cubit.addEvent(event);
    if (!mounted) return;

    if (res) {
      Navigator.of(context).pop(UpdateEnum.updated);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? loc.eventEdit : loc.eventAdd),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              BlocBuilder<EventAddUpdateCubit, EventAddUpdateState>(
                builder: (context, state) {
                  if (state.conflicts.isEmpty) return const SizedBox.shrink();
                  final conflict = state.conflicts.first;

                  return Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.warning_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      title: Text(
                        loc.eventConflictsWith(
                          conflict.name,
                          conflict.attendees.isEmpty
                              ? ""
                              : conflict.attendees
                                  .map((p) => p.name)
                                  .join(", "),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  );
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: loc.name),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? loc.error : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: loc.description),
                maxLines: 3,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: loc.location),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.allDay),
                value: _allDay,
                onChanged: (value) => setState(() => _allDay = value),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(
                  MaterialLocalizations.of(context).formatMediumDate(_start),
                ),
                onTap: _pickDate,
              ),
              if (!_allDay)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_rounded),
                  title: Text(
                    "${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_start))} \u2013 ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_end))}",
                  ),
                  onTap: () => _pickTime(isStart: true),
                  onLongPress: () => _pickTime(isStart: false),
                ),
              const SizedBox(height: 8),
              Text(loc.attendees),
              const SizedBox(height: 8),
              BlocBuilder<EventAddUpdateCubit, EventAddUpdateState>(
                builder: (context, state) {
                  if (state.persons.isEmpty) {
                    return Text(loc.noTags);
                  }

                  return Wrap(
                    runSpacing: 8,
                    spacing: 5,
                    children: [
                      for (final person in state.persons)
                        FilterChip(
                          label: Text(person.name),
                          selected: state.selectedPersons.contains(person),
                          onSelected: (selected) {
                            _cubit.selectPerson(person, selected);
                            _checkConflicts();
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
