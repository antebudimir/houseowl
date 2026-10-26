import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/models/event.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/member.dart';
import 'package:houseowl/services/api/api_service.dart';

/// State for the event editor: the household's members (for the attendee
/// chips), the current selection, and the live conflict banner fed by the
/// server's /conflicts pre-check (the save itself is authoritatively
/// re-checked and hard-blocked with 409).
class EventAddUpdateCubit extends Cubit<EventAddUpdateState> {
  final Household household;

  EventAddUpdateCubit(this.household, {Set<Member> selectedPersons = const {}})
      : super(EventAddUpdateState(selectedPersons: selectedPersons)) {
    getMembers();
  }

  Future<void> getMembers() async {
    final members = await ApiService.getInstance()
            .getHousehold(household)
            .then((r) => r.household?.member) ??
        const <Member>[];
    emit(state.copyWith(persons: members));
    // The page triggers checkConflicts with the current time slot; member
    // selection changes go through selectPerson below.
  }

  void selectPerson(Member person, bool selected) {
    final persons = Set<Member>.from(state.selectedPersons);
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
  final List<Member> persons;
  final Set<Member> selectedPersons;
  final List<Event> conflicts;

  const EventAddUpdateState({
    this.persons = const [],
    this.selectedPersons = const {},
    this.conflicts = const [],
  });

  EventAddUpdateState copyWith({
    List<Member>? persons,
    Set<Member>? selectedPersons,
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
