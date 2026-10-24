import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/models/event.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/services/api/api_service.dart';

/// State for the event editor: the household's persons (for the attendee
/// chips), the current selection, and the live conflict banner fed by the
/// server's /conflicts pre-check (the save itself is authoritatively
/// re-checked and hard-blocked with 409).
class EventAddUpdateCubit extends Cubit<EventAddUpdateState> {
  final Household household;

  EventAddUpdateCubit(this.household, {Set<Person> selectedPersons = const {}})
      : super(EventAddUpdateState(selectedPersons: selectedPersons)) {
    getPersons();
  }

  Future<void> getPersons() async {
    final persons = await ApiService.getInstance()
        .getPersons(household)
        .then((v) => v ?? const <Person>[]);
    emit(state.copyWith(persons: persons));
    // The page triggers checkConflicts with the current time slot; person
    // selection changes go through selectPerson below.
  }

  void selectPerson(Person person, bool selected) {
    final persons = Set<Person>.from(state.selectedPersons);
    selected ? persons.add(person) : persons.remove(person);
    emit(state.copyWith(selectedPersons: persons));
  }

  /// Re-runs the conflict pre-check for the given slot; called by the page
  /// whenever the time selection changes.
  Future<void> checkConflicts({
    required DateTime start,
    required DateTime end,
    int? excludeId,
  }) async {
    final conflicts = await ApiService.getInstance().getEventConflicts(
      household,
      start: start,
      end: end,
      attendeeIds: state.selectedPersons.map((p) => p.id).toList(),
    );
    emit(state.copyWith(
      conflicts: conflicts
              ?.where((e) => e.id != excludeId)
              .toList() ??
          const [],
    ));
  }

  void clearConflicts() {
    emit(state.copyWith(conflicts: const []));
  }
}

class EventAddUpdateState extends Equatable {
  final List<Person> persons;
  final Set<Person> selectedPersons;
  final List<Event> conflicts;

  const EventAddUpdateState({
    this.persons = const [],
    this.selectedPersons = const {},
    this.conflicts = const [],
  });

  EventAddUpdateState copyWith({
    List<Person>? persons,
    Set<Person>? selectedPersons,
    List<Event>? conflicts,
  }) =>
      EventAddUpdateState(
        persons: persons ?? this.persons,
        selectedPersons: selectedPersons ?? this.selectedPersons,
        conflicts: conflicts ?? this.conflicts,
      );

  @override
  List<Object?> get props => [persons, selectedPersons, conflicts];
}
