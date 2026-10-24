import 'package:houseowl/models/household.dart';
import 'package:houseowl/models/person.dart';
import 'package:houseowl/services/api/api_service.dart';
import 'package:houseowl/services/storage/mem_storage.dart';
import 'package:houseowl/services/transaction.dart';

class TransactionPersonsGet extends Transaction<List<Person>> {
  final Household household;

  TransactionPersonsGet({
    required this.household,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPersonsGet",
        );

  @override
  Future<List<Person>> runLocal() async {
    return await MemStorage.getInstance().readPersons(household) ?? [];
  }

  @override
  Future<List<Person>?> runOnline() async {
    final persons = await ApiService.getInstance().getPersons(household);
    if (persons != null) {
      MemStorage.getInstance().writePersons(household, persons);
    }

    return persons;
  }
}

class TransactionPersonAdd extends Transaction<bool> {
  final Household household;
  final Person person;

  TransactionPersonAdd({
    required this.household,
    required this.person,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPersonAdd",
        );

  factory TransactionPersonAdd.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionPersonAdd(
        household: Household.fromJson(map['household']),
        person: Person.fromJson(map['person']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "person": person.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final persons = await MemStorage.getInstance().readPersons(household) ?? [];
    persons.add(Person(
      name: person.name,
      role: person.role,
      phone: person.phone,
      email: person.email,
      notes: person.notes,
      birthday: person.birthday,
      userId: person.userId,
    ));
    MemStorage.getInstance().writePersons(household, persons);

    return true;
  }

  @override
  Future<bool?> runOnline() async =>
      await ApiService.getInstance().addPerson(household, person) != null;
}

class TransactionPersonUpdate extends Transaction<bool> {
  final Household household;
  final Person person;

  TransactionPersonUpdate({
    required this.household,
    required this.person,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPersonUpdate",
        );

  factory TransactionPersonUpdate.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionPersonUpdate(
        household: Household.fromJson(map['household']),
        person: Person.fromJson(map['person']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "person": person.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final persons = await MemStorage.getInstance().readPersons(household);
    if (persons == null || person.id == null) return false;
    final int i = persons.indexWhere((e) => e.id == person.id);
    if (i < 0) return false;
    persons[i] = person;
    MemStorage.getInstance().writePersons(household, persons);

    return true;
  }

  @override
  Future<bool?> runOnline() => ApiService.getInstance().updatePerson(person);
}

class TransactionPersonRemove extends Transaction<bool> {
  final Household household;
  final Person person;

  TransactionPersonRemove({
    required this.household,
    required this.person,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPersonRemove",
        );

  factory TransactionPersonRemove.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionPersonRemove(
        household: Household.fromJson(map['household']),
        person: Person.fromJson(map['person']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "person": person.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final persons = await MemStorage.getInstance().readPersons(household);
    if (persons == null) return false;
    persons.removeWhere((e) =>
        (person.id != null && e.id == person.id) ||
        (person.id == null && e.id == null && e.name == person.name));
    MemStorage.getInstance().writePersons(household, persons);

    return true;
  }

  @override
  Future<bool?> runOnline() => ApiService.getInstance().deletePerson(person);
}