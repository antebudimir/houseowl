import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/services/api/api_service.dart';

/// State for the document editor. It loads the household's members/contacts
/// for the person selector, mirroring the task assignee dropdown.
class DocumentAddUpdateCubit extends Cubit<DocumentAddUpdateState> {
  final Household household;

  DocumentAddUpdateCubit(this.household)
      : super(const DocumentAddUpdateState()) {
    getPersons();
  }

  Future<void> getPersons() async {
    final persons = await ApiService.getInstance().getPersons(household) ??
        const <Person>[];
    emit(state.copyWith(persons: persons));
  }
}

class DocumentAddUpdateState extends Equatable {
  final List<Person> persons;

  const DocumentAddUpdateState({this.persons = const []});

  DocumentAddUpdateState copyWith({List<Person>? persons}) =>
      DocumentAddUpdateState(persons: persons ?? this.persons);

  @override
  List<Object?> get props => [persons];
}
